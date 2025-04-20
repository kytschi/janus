/**
 * Janus - The spirit of the doorways
 *
 * @package     Janus\Janus
 * @author 		Mike Welsh
 * @copyright   2023 Mike Welsh
 * @version     0.0.2 alpha
 *
 * Copyright 2023 Mike Welsh
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public
 * License along with this library; if not, write to the
 * Free Software Foundation, Inc., 51 Franklin St, Fifth Floor,
 * Boston, MA  02110-1301, USA.
*/
namespace Janus;

use Janus\Controllers\Blacklist;
use Janus\Controllers\Controller;
use Janus\Controllers\Database;
use Janus\Controllers\Logs;
use Janus\Controllers\Patterns;
use Janus\Controllers\Settings;
use Janus\Controllers\Users;
use Janus\Controllers\Watchlist;
use Janus\Controllers\Whitelist;
use Janus\Exceptions\Exception;
use Janus\Helpers\Captcha;
use Janus\Ui\Head;

class Janus extends Controller
{
    public function __construct(string db, string url_key = "", bool cron = false, bool migrations = false)
    {
        var splits, username = "", password = "";

        let splits = explode(":", db);

        if (!isset(splits[1])) {
            throw new Exception("Invalid database string", (cron || migrations) ? true : false);
        }

        switch (splits[0]) {
            case "mysql":
                let splits = this->setCredentials(splits[1]);
                let username = splits[0];
                let password = splits[1];
                break;
            case "sqlite":
                if (!file_exists(str_replace("sqlite:", "", db))) {
                    throw new Exception("SQLite DB not found", (cron || migrations) ? true : false);
                }
                break;
            default:
                //Just to stop the compiler warning.
                this->throwError("Invalid database connection", (cron || migrations) ? true : false);
                break;
        }

        if (!file_exists(url_key)) {
            throw new Exception("Invalid key", (cron || migrations) ? true : false);
        }

        let this->db = new Database(db, username, password);

        var settings;
        let settings = this->db->get("SELECT * FROM settings LIMIT 1");
        if (empty(settings)) {
            this->db->execute("INSERT INTO settings
            (
                ip_lookup,
                service_lookup,
                firewall_command,
                firewall_cfg_folder,
                firewall_cfg_file_v4,
                cron_folder,
                cron_running,
                webuser,
                firewall_cfg_file_v6,
                firewall_command_v6
            )
            VALUES
            (
                1,
                1,
                '/usr/sbin/iptables',
                '/etc/iptables/',
                'rules.v4',
                '/var/www/janus/cron',
                0,
                'www-data',
                'rules.v6',
                '/usr/sbin/ip6tables'
            )");
            let settings = this->db->get("SELECT * FROM settings LIMIT 1");
        }
        let settings->db_file = db;
        let settings->url_key_file = url_key;
        let settings->url_key = trim(file_get_contents(url_key), "\n");
        let this->settings = settings;

        if (cron) {
            this->scan("/scan", cron);
            return;
        } elseif (migrations) {
            this->runMigrations();
            return;
        }

        if (strpos(_SERVER["REQUEST_URI"], this->settings->url_key) === false) {
            header("HTTP/1.1 404 Not Found");
            die();
        }
        
        if (session_status() === 1) {
            session_name("janus");
            ini_set("session.gc_maxlifetime", 3600);
            ini_set("session.cookie_lifetime", 3600);
            session_start();
        }

        var routes = [
            "/dashboard": "dashboard",
            "/blacklist": "blacklist",            
            "/logout": "logout",
            "/logs": "logs",
            "/patterns": "patterns",
            "/the-secure-door": "login",
            "/scan-warn": "scanWarn",
            "/scan": "scan",
            "/settings": "settings",
            "/updates-available": "updatesAvailable",
            "/users": "users",
            "/watchlist": "watchlist",
            "/whitelist": "whitelist"
        ];

        var code = 404, path, parsed, output = "", route, func, logged_in = false;

        let parsed = parse_url(_SERVER["REQUEST_URI"]);
        let path = "/" . trim(parsed["path"], "/");

        if (path == this->urlAddKey("")) {
            let path = this->urlAddKey("/dashboard");
        }

        if (!isset(_SESSION["janus"])) {
            let path = this->urlAddKey("/the-secure-door");
            let _SESSION["janus"] = null;
        }

        if (empty(_SESSION["janus"])) {
            let path = this->urlAddKey("/the-secure-door");
        } else {
            let logged_in = true;
            let code = 200;
        }

        try {
            let route = this->db->get("SELECT * FROM migrations");
            if (empty(route)) {
                throw new \Exception("Run migrations");
            }

            let parsed = shell_exec("ls " . rtrim(this->settings->cron_folder, "/") . "/migrations/*.sql");
            let output = explode("\n", parsed);
            for func in output {
                if (empty(func)) {
                    continue;
                }
                let route = this->db->get(
                    "SELECT * FROM migrations WHERE migration = :migration",
                    [
                        "migration": basename(func)
                    ]
                );
                
                if (empty(route)) {
                    throw new \Exception("Run migrations");
                }
            }
        } catch \Exception, route {
            this->writeMigrations();
            let path = this->urlAddKey("/updates-available");
        }

        try {
            for route, func in routes {
                if (strpos(path, this->urlAddKey(route)) !== false) {
                    let output = this->{func}(path);
                    break;
                }
            }
        } catch \Exception, route {
            throw new Exception(route->getMessage());
        }
        
        if (empty(output)) {
            let code = 404;
            let output = this->notFound();
        }

        this->head(code);
        echo output;
        this->footer(logged_in);
    }

    private function blacklist(string path)
    {
        var controller;
        let controller = new Blacklist();
        return controller->router(path, this->db, this->settings);
    }

    private function dashboard(string path)
    {
        var data, html;
        let html = this->pageTitle("Dashboard") . "
        <div class='row'>" . 
            this->patternsUI() .
            "<div>
                <table class='table'>
                    <tbody>
                        <tr>
                            <th>Blacklisted</th>
                            <td>";
            let data = this->db->get("SELECT COUNT(id) AS total FROM blacklist");
            let html .= (data) ? data->total : 0;
            let html .= "</td>
                        </tr>
                        <tr>
                            <th>Whitelisted</th>
                            <td>";
            let data = this->db->get("SELECT COUNT(id) AS total FROM whitelist");
            let html .= (data) ? data->total : 0;
            let html .= "</td>
                        </tr>
                        <tr>
                            <th>Watching</th>
                            <td>";
            try {
                let data = this->db->get("SELECT COUNT(id) AS total FROM watchlist");
                let html .= (data) ? data->total : 0;
            } catch \Exception, data {
                let html .= "<strong>PLEASE RUN MIGRATIONS</strong>";
            }
            let html .= "</td>
                        </tr>
                        <tr>
                            <th>Available patterns</th>
                            <td>";
            let data = this->db->get("SELECT COUNT(id) AS total FROM block_patterns");
            let html .= (data) ? data->total : 0;
            let html .= "</td>
                        </tr>
                        <tr>
                            <th>Patterns blocked</th>
                            <td>";
            let data = this->db->get("SELECT COUNT(id) AS total FROM found_block_patterns");
            let html .= (data) ? data->total : 0;
            let html .= "</td>
                        </tr>
                    </tbody>
                </table>
            </div>" .
        "</div>
        <h2><span>Blacklist summary</span></h2>
        <div class='row'>" . 
            (this->settings->service_lookup ? this->ipServicesUI() : "") . 
            (this->settings->ip_lookup ? this->ipCountriesUI() : "") . 
        "</div>";

        return html;
    }

    private function footer(bool logged_in = false)
    {
        echo "</main></body></html>";
    }

    private function head(int code = 200)
    {
        var head;
        let head = new Head(this->settings);

        if (code == 404) {
            header("HTTP/1.1 404 Not Found");
        } elseif (code == 403) {
            header("HTTP/1.1 403 Forbidden");
        }

        echo "<!DOCTYPE html>
            <html lang='en'>" . head->build() . "
                <body>
                    <div class='background-image'></div>
                    <main>";
    }

    private function ipCountriesUI()
    {
        var height = 200, labels = [], totals = [], colours = [], data;

        let data = this->db->all("SELECT COUNT(id) AS total, country FROM blacklist GROUP BY country ORDER BY total DESC");
        if (!empty(data)) {
            var item;
            for item in data {
                let labels[] = "\"" . str_replace(["\""], "", item->country) . "\"";
                let totals[] = intval(item->total);
                let colours[] = "\"#" . substr(md5(item->country), 3, 6) . "\"";
            }

            let height = count(data) * 30;
            if (height < 200) {
                let height = 200;
            }
        }
        
        let labels = implode(",", labels);
        let totals = implode(",", totals);
        let colours = implode(",", colours);

        return  "<div class='box'>
        <div class='box-title'>
            <span>Locations</span>
        </div>
        <div class='box-body'>
            <canvas id='countries' width='600' height='" . height . "'></canvas>
            <script type='text/javascript'>
                var ctx_countries = document.getElementById('countries').getContext('2d');
                
                var countries = new Chart(ctx_countries, {
                    type: 'horizontalBar',
                    data: {
                        labels: [" . labels . "],
                        datasets: [
                            {
                                label: 'IPs',
                                data: [" . totals . "],
                                backgroundColor: [" . colours . "],
                                borderColor: '#5E5E60',
                                borderWidth: 0.4
                            },
                        ]
                    },
                    options: {
                        indexAxis: 'y',
                        scales: {
                            xAxes: [
                                {
                                    gridLines: {
                                        display: true
                                    },
                                    ticks: {
                                        beginAtZero: true
                                    },
                                    position: 'top'
                                }
                            ],
                        },
                        responsive: true,
                        legend: {
                            display: false
                        },
                        plugins: {
                            legend: {
                                position: 'right'
                            },
                            title: {
                                display: false
                            }
                        }
                    }
                });
            </script>
        </div></div>";
    }

    private function ipServicesUI()
    {
        var height = 200, labels = [], totals = [], colours = [], data;

        let data = this->db->all("SELECT COUNT(id) AS total, service FROM blacklist GROUP BY service ORDER BY total DESC");
        if (!empty(data)) {
            var item;
            for item in data {
                let labels[] = "\"" . str_replace(["\""], "", item->service) . "\"";
                let totals[] = intval(item->total);
                let colours[] = "\"#" . substr(md5(item->service), 3, 6) . "\"";
            }

            let height = count(data) * 30;
            if (height < 200) {
                let height = 200;
            }
        }
        
        let labels = implode(",", labels);
        let totals = implode(",", totals);
        let colours = implode(",", colours);

        return  "<div class='box'>
        <div class='box-title'>
            <span>Services</span>
        </div>
        <div class='box-body'>
            <canvas id='services' width='600' height='" . height . "'></canvas>
            <script type='text/javascript'>
                var ctx_services = document.getElementById('services').getContext('2d');
                
                var services = new Chart(ctx_services, {
                    type: 'horizontalBar',
                    data: {
                        labels: [" . labels . "],
                        datasets: [
                            {
                                label: 'IPs',
                                data: [" . totals . "],
                                backgroundColor: [" . colours . "],
                                borderColor: '#5E5E60',
                                borderWidth: 0.4
                            },
                        ]
                    },
                    options: {
                        indexAxis: 'y',
                        scales: {
                            xAxes: [
                                {
                                    gridLines: {
                                        display: true
                                    },
                                    ticks: {
                                        beginAtZero: true
                                    },
                                    position: 'top'
                                }
                            ],
                        },
                        responsive: true,
                        legend: {
                            display: false
                        },
                        plugins: {
                            legend: {
                                position: 'right'
                            },
                            title: {
                                display: false
                            }
                        }
                    }
                });
            </script>
        </div></div>";
    }

    private function login(string path)
    {
        var html, captcha;
        let captcha = new Captcha();

        let html = "<h1><span>Login</span></h1>";

        if (!empty(_POST)) {
            if (isset(_POST["login"])) {
                if (!this->validate(_POST, ["u", "p", "janus_captcha"])) {
                    let html .= this->error("Missing required inputs");
                } else {
                    if (!captcha->validate()) {
                        let html .= this->error("Invalid captcha");
                    } else {
                        var user;
                        let user = this->db->get(
                            "SELECT * FROM users WHERE name=:name",
                            [
                                "name": _POST["u"]
                            ]
                        );

                        if (!empty(user)) {
                            if (password_verify(_POST["p"], user->password)) {
                                let _SESSION["janus"] = md5(time());
                                this->redirect(this->urlAddKey("/dashboard"));
                            }
                        }
                        
                        let _SESSION["janus"] = null;
                        session_write_close();

                        let html .= this->error("Access denied");
                    }
                }
            }
        }

        let html .= "
        <form method='post'>        
            <table id='login' class='table wfull'>
                <tbody>
                    <tr>
                        <th>Username<span class='required'>*</span></th>
                        <td>
                            <input type='text' name='u' placeholder='what is your username?'>
                        </td>
                    </tr>
                    <tr>
                        <th>Password<span class='required'>*</span></th>
                        <td>
                            <input type='password' name='p' placeholder='your secret password please'>
                        </td>
                    </tr>
                    <tr>
                        <th class='text-top'>Captcha<span class='required'>*</span></th>
                        <td>
                            " . captcha->draw() . "
                        </td>
                    </tr>
                </tbody>
                <tfoot>
                    <tr>
                        <td colspan='2'>
                            <button type='submit' name='login' class='float-right'>login</button>
                        </td>
                    </tr>
                </tfoot>
            </table>
        </form>";

        return html;
    }

    private function logout(string path)
    {
        let _SESSION["janus"] = null;
        session_write_close();
        this->redirect(this->urlAddKey("/the-secure-door"));
    }

    private function logs(string path)
    {
        var controller;
        let controller = new Logs();
        return controller->router(path, this->db, this->settings);
    }

    private function notFound()
    {
        return "
            <div class='box'>
                <div class='box-title'>
                    <span>Error</span>
                </div>
                <div class='box-body'>
                    <h1>Page not found</h1>
                </div>
                <div class='box-footer'>
                    <button type='button' onclick='window.history.back()'>back</button>
                </div>
            </div>";
    }

    private function patterns(string path)
    {
        var controller;
        let controller = new Patterns();
        return controller->router(path, this->db, this->settings);
    }

    private function patternsUI()
    {
        var height = 200, labels = [], totals = [], colours = [], data;

        let data = this->db->all("SELECT COUNT(id) AS total, category FROM found_block_patterns GROUP BY category ORDER BY total DESC");
        if (!empty(data)) {
            var item;
            for item in data {
                let labels[] = "\"" . str_replace(["\""], "", item->category) . "\"";
                let totals[] = intval(item->total);
                let colours[] = "\"#" . substr(md5(item->category), 3, 6) . "\"";
            }

            let height = count(data) * 30;
            if (height < 200) {
                let height = 200;
            }
        }
        
        let labels = implode(",", labels);
        let totals = implode(",", totals);
        let colours = implode(",", colours);

        return  "<div class='box'>
        <div class='box-title'>
            <span>Block patterns</span>
        </div>
        <div class='box-body'>
            <canvas id='patterns' width='600' height='" . height . "'></canvas>
            <script type='text/javascript'>
                var ctx_patterns = document.getElementById('patterns').getContext('2d');
                
                var patterns = new Chart(ctx_patterns, {
                    type: 'horizontalBar',
                    data: {
                        labels: [" . labels . "],
                        datasets: [
                            {
                                label: 'patterns',
                                data: [" . totals . "],
                                backgroundColor: [" . colours . "],
                                borderColor: '#5E5E60',
                                borderWidth: 0.4
                            },
                        ]
                    },
                    options: {
                        indexAxis: 'y',
                        scales: {
                            xAxes: [
                                {
                                    gridLines: {
                                        display: true
                                    },
                                    ticks: {
                                        beginAtZero: true
                                    },
                                    position: 'top'
                                }
                            ],
                        },
                        responsive: true,
                        legend: {
                            display: false
                        },
                        plugins: {
                            legend: {
                                position: 'right'
                            },
                            title: {
                                display: false
                            }
                        }
                    }
                });
            </script>
        </div></div>";
    }

    private function runMigrations()
    {
        var migration, migrations, err, found, file, line;

        echo " Running migrations\n";
        let migration = shell_exec("ls " . rtrim(this->settings->cron_folder, "/") . "/migrations/*.sql");
        if (empty(migration)) {
            echo " Nothing to migrate!\n";
            return;
        }
        let migrations = explode("\n", migration);
        if (!count(migrations)) {
            echo " Nothing to migrate!\n";
            return;
        }

        for migration in migrations {
            if (empty(migration)) {
                continue;
            }

            try {
                let found = this->db->get(
                    "SELECT * FROM migrations WHERE migration=:migration",
                    [
                        "migration": basename(migration)
                    ]
                );
            } catch \Exception, err {
                let found = false;
            }

            if (found) {
                continue;
            }

            try {
                let file = fopen(migration, "r");
                if (file) {
                    let line = fgets(file);
                    while (line !== false) {
                        if (!empty(line) && line != "\n") {
                            if (
                                strpos(line, "IGNORE SQLITE") !== false &&
                                strpos(this->settings->db_file, "sqlite:") !== false
                            ) {
                                break;
                            }

                            if (substr(line, 0, 2) !== "/*") {
                                echo " " . line . "\n";
                                let found = this->db->execute(line);
                                if (!is_bool(found)) {
                                    throw new Exception(found);
                                }
                            }
                        }
                        let line = fgets(file);
                    }

                    fclose(file);

                    echo " " . basename(migration) . " successfully run\n";
                    let found = this->db->execute(
                        "INSERT INTO migrations (migration) VALUES(:migration)",
                        [
                            "migration": basename(migration)
                        ]
                    );
                    if (!is_bool(found)) {
                        throw new Exception(found);
                    }
                }
            } catch \Exception, err {
                echo " Failed to run the migration " . basename(migration) .
                    "\n Error: " . err->getMessage() . "\n";
            }
        }
        echo " Migrations complete\n";
    }

    private function saveIP(pattern, ip, ipvsix)
    {
        var data, country, service, whois;

        this->db->execute(
            "INSERT INTO found_block_patterns
                (ip, pattern, label, category, created_at) 
            VALUES 
                (
                    :ip,
                    :pattern,
                    :label,
                    :category,
                    :created_at
                )",
            [
                "ip": ip,
                "pattern": pattern->pattern,
                "label": pattern->label,
                "category": pattern->category,
                "created_at": date("Y-m-d")
            ]
        );

        let data = this->db->get("SELECT * FROM whitelist WHERE ip=:ip", ["ip": ip]);
        if (!empty(data)) {
            return;
        }

        let country = "UNKNOWN";
        if (this->settings->ip_lookup) {
            let country = this->getCountry(ip);
        }

        let service = "UNKNOWN";
        let whois = "UNKNOWN";
        if (this->settings->service_lookup) {
            let data = this->getService(ip);
            let whois = data[0];
            if (data[1]) {
                let service = data[1];
            }
        }

        let data = this->db->get("SELECT id FROM blacklist WHERE ip=:ip", ["ip": ip]);
        if (!empty(data)) {
            return;
        }

        this->db->execute(
            "INSERT INTO blacklist
                (ip, country, whois, service, ipvsix, created_at) 
            VALUES 
                (
                    :ip,
                    :country,
                    :whois,
                    :service,
                    :ipvsix, 
                    :created_at
                )",
            [
                "ip": ip,
                "country": country,
                "whois": whois,
                "service": service,
                "ipvsix": (ipvsix) ? 1 : 0,
                "created_at": date("Y-m-d")
            ]
        );
    }

    private function saveWatch(ip, log_id, log_line)
    {
        var data;

        let data = this->db->get("SELECT * FROM watchlist WHERE ip=:ip", ["ip": ip]);
        if (!empty(data)) {
            return;
        }

        let data = this->db->get(
            "SELECT id FROM watchlist_log_entries WHERE ip=:ip AND log_line=:log_line",
            [
                "ip": ip,
                "log_line": log_line
            ]
        );
        if (!empty(data)) {
            return;
        }

        this->db->execute(
            "INSERT INTO watchlist_log_entries
                (ip, log_id, log_line, created_at) 
            VALUES 
                (
                    :ip,
                    :log_id,
                    :log_line,
                    :created_at
                )",
            [
                "ip": ip,
                "log_id": log_id,
                "log_line": log_line,
                "created_at": date("Y-m-d")
            ]
        );
    }

    private function scan(string path, bool cron = false)
    {
        if (this->settings->cron_running && !cron) {
            return this->pageTitle("Scanning logs") . "
            <div class='row'>
                <div class='box'>
                    <div class='box-title'>
                        <span>Scan running</span>
                    </div>
                    <div class='box-body'>
                        <p>The scan is already running please wait for it to finish before trying again</p>
                    </div>
                    <div class='box-footer'>
                        <a href='" . this->urlAddKey("/dashboard") . "' class='button'>Back to dashboard</a>
                    </div>
                </div>
            </div>";
        }

        var folder, dir, logs, log, line, pattern, patterns = [],
            matches, db_logs, errors = [], html, ipvsix, ip, line_number, last_line, err;

        try {
            this->db->execute("UPDATE settings SET cron_running=1");

            let patterns = this->db->all("SELECT * FROM block_patterns");
            let db_logs = this->db->all("SELECT * FROM logs");
            
            for folder in db_logs {
                let dir = shell_exec("ls " . folder->log);
                if (empty(dir)) {
                    if (cron) {
                        echo "Failed to list the log/folder, " . folder->log . "\n";
                    } else {
                        let errors[] = "Failed to list the log/folder, " . folder->log;
                    }
                    continue;
                }

                //Check the md5 hash to see if it has changed.
                let line = md5_file(folder->log);
                if (folder->md5_hash) {
                    if (folder->md5_hash == line) {
                        continue;
                    }
                }

                // If the last read of the log is more than 24hrs old rest line pointer.
                if (empty(folder->last_read)) {
                    let folder->last_line_number = 0;
                } else {
                    let err = strtotime(folder->last_read) - time();
                    if (err > 86400) {
                        let folder->last_line_number = 0;
                    }
                }

                this->db->execute(
                    "UPDATE logs SET md5_hash=:md5_hash, last_read=:last_read WHERE id=:id",
                    [
                        "id": folder->id,
                        "md5_hash": line,
                        "last_read": date("Y-m-d H:i:s")
                    ]
                );

                let logs = explode("\n", dir);
                if (!count(logs)) {
                    continue;
                }

                for log in logs {
                    if (empty(log)) {
                        continue;
                    }

                    let dir = new \SplFileObject(log);
                    if (dir->eof()) {
                        continue;
                    }

                    let line_number = 0;
                    if (folder->last_line_number) {
                        dir->seek(folder->last_line_number);
                    }

                    let last_line = "";
                    while (!dir->eof()) {
                        let line_number = dir->key();
                        let line = dir->current();
                        if (empty(line)) {
                            continue;
                        }
                        let last_line = line;

                        let ip = null;
                        let ipvsix = null;

                        if (
                            preg_match(
                                "/([a-f0-9:]+:+)+[a-f0-9]+/",
                                line,
                                matches
                            )
                        ) {
                            let ipvsix = this->getIPVSIX(line);
                            if (ipvsix) {
                                //Always ignore localhost, should I?
                                if (ipvsix == "::1") {
                                    continue;
                                }
                                let ip = null;
                                this->saveWatch(ipvsix, folder->id, line);
                            }
                        }

                        if (empty(ipvsix)) {
                            if (preg_match("/\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}/", line, matches)) {
                                //Always ignore localhost.
                                if (matches[0] == "127.0.0.1") {
                                    continue;
                                }
                                let ipvsix = null;
                                let ip = matches[0];
                                this->saveWatch(ip, folder->id, line);
                            }
                        }

                        if (ipvsix || ip) {
                            for pattern in patterns {
                                if (strpos(strtolower(line), strtolower(pattern->pattern)) === false) {
                                    continue;
                                }

                                if (ipvsix) {
                                    this->saveIP(pattern, ipvsix, true);
                                } else {
                                    this->saveIP(pattern, ip, false);
                                }                            
                            }
                        }
                        dir->next();
                    }

                    this->db->execute(
                        "UPDATE logs SET last_line_number=:last_line_number,last_line=:last_line WHERE id=:id",
                        [
                            "id": folder->id,
                            "last_line_number": line_number,
                            "last_line": last_line
                        ]
                    );
                }
            }

            this->db->execute("UPDATE settings SET cron_running=0");
            this->writeCronFiles(cron);

            let html = this->pageTitle("Scanning logs") . "
            <div class='row'>
                <div class='box'>
                    <div class='box-title'>
                        <span>Scan complete</span>
                    </div>
                    <div class='box-body'>
                        <p>All done</p>";
            if (errors) {
                let html .= "<p><strong>Errors Occcurred</strong></p>";
                for folder in errors {
                    let html .= "<p>" . folder . "</p>";
                }
            }
            let html .= "</div>
                    <div class='box-footer'>
                        <a href='". this->urlAddKey("/dashboard") . "' class='button'>Back to dashboard</a>
                    </div>
                </div>
            </div>";
            
            return html;
        } catch \Exception, err {
            this->db->execute("UPDATE settings SET cron_running=0");
            throw new Exception(err->getMessage(), cron);
        }
    }

    private function scanWarn(string path)
    {
        if (this->settings->cron_running) {
            return this->pageTitle("Scanning logs") . "
            <div class='row'>
                <div class='box'>
                    <div class='box-title'>
                        <span>Scan running</span>
                    </div>
                    <div class='box-body'>
                        <p>The scan is already running please wait for it to finish before trying again</p>
                    </div>
                    <div class='box-footer'>
                        <a href='". this->urlAddKey("/dashboard") . "' class='button'>Back to dashboard</a>
                    </div>
                </div>
            </div>";
        }

        return this->pageTitle("Scan logs") . "
        <div class='row'>
            <div class='box'>
                <div class='box-title'>
                    <span>Scan the logs</span>
                </div>
                <div class='box-body'>
                    <p>Scanning can take sometime</p>
                </div>
                <div class='box-footer'>
                    <a href='". this->urlAddKey("/scan") . "' class='button float-right'>Go</a>
                </div>
            </div>
        </div>";
    }

    private function setCredentials(string str)
    {
        var splits, key, username = "", password = "";
        let splits = explode(";", str);
        for key in splits {
            if (strpos(key, "UID=") !== false) {
                let username = str_replace(["UID=", "'", "\""], "", key);
            } elseif (strpos(key, "PWD=") !== false) {
                let password = str_replace(["PWD=", "'", "\""], "", key);
            }
        }

        return [username, password];
    }

    private function settings(string path)
    {
        var controller;
        let controller = new Settings();
        return controller->router(path, this->db, this->settings);
    }

    private function updatesAvailable(string path)
    {
        return this->pageTitle("Updates Available", false) . "
        <div class='row'>
            <div class='box'>
                <div class='box-body'>
                    Please run the migrations script before proceeding
                </div>
            </div>
        </div>";
    }

    private function users(string path)
    {
        var controller;
        let controller = new Users();
        return controller->router(path, this->db, this->settings);
    }

    private function watchlist(string path)
    {
        var controller;
        let controller = new Watchlist();
        return controller->router(path, this->db, this->settings);
    }

    private function whitelist(string path)
    {
        var controller;
        let controller = new Whitelist();
        return controller->router(path, this->db, this->settings);
    }

    private function throwError(string message, bool commandline)
    {
        throw new Exception(message, commandline);
    }
}