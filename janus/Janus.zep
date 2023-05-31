/**
 * Janus - The spirit of the doorways
 *
 * @package     Janus\Janus
 * @author 		Mike Welsh
 * @copyright   2023 Mike Welsh
 * @version     0.0.1 alpha
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
use Janus\Controllers\Whitelist;
use Janus\Exceptions\Exception;
use Janus\Helpers\Captcha;
use Janus\Ui\Head;

class Janus extends Controller
{
    private settings;

    public function __construct(string db)
    {
        if (!file_exists(db)) {
            throw new Exception("SQLite DB not found");
        }

        let this->db = new Database(db);
        let this->settings = this->db->get("SELECT * FROM settings LIMIT 1");
        
        if (session_status() === 1) {
            session_name("janus");
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
            "/users": "users",
            "/whitelist": "whitelist"
        ];

        var code = 200, path, parsed, output = "", route, func, logged_in = false;

        let parsed = parse_url(_SERVER["REQUEST_URI"]);
        let path = "/" . trim(parsed["path"], "/");

        if (path == "/") {
            let path = "/dashboard";
        }

        if (!isset(_SESSION["janus"])) {
            let path = "/the-secure-door";
            let _SESSION["janus"] = null;
        }

        if (empty(_SESSION["janus"])) {
            let path = "/the-secure-door";
        } else {
            let logged_in = true;
        }

        for route, func in routes {
            if (strpos(path, route) !== false) {
                let output = this->{func}(path);
                break;
            }
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
        return this->pageTitle("Dashboard") . "        
        <div class='row'>" .
            this->patternsUI() .            
        "</div>
        <h2><span>IP summary</span></h2>
        <div class='row'>" . 
            (this->settings->service_lookup ? this->ipServicesUI() : "") . 
            (this->settings->ip_lookup ? this->ipCountriesUI() : "") . 
        "</div>";
    }

    private function footer(bool logged_in = false)
    {
        echo "</main></body></html>";
    }

    private function head(int code = 200)
    {
        var head;
        let head = new Head();

        if (code == 404) {
            header("HTTP/1.1 404 Not Found");
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
                let labels[] = "\"" . item->country . "\"";
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
                let labels[] = "\"" . item->service . "\"";
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
                                this->redirect("/dashboard");
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
        this->redirect("/the-secure-door");
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
                let labels[] = "\"" . item->category . "\"";
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

    private function scan(string path)
    {
        var folder, dir, logs, log, lines, line, pattern, patterns = [],
            matches, db_logs, data, country, service, whois;

        let patterns = this->db->all("SELECT * FROM block_patterns");
        let db_logs = this->db->all("SELECT * FROM logs");
        
        for folder in db_logs {
            let dir = shell_exec("ls " . folder->log);
            if (empty(dir)) {
                throw new Exception("Failed to list the logs folder");
            }
            let logs = explode("\n", dir);
            if (!count(logs)) {
                continue;
            }

            for log in logs {
                if (empty(log)) {
                    continue;
                }

                let lines = explode("\n", file_get_contents(log));
                if (empty(lines)) {
                    continue;
                }

                for line in lines {
                    if (empty(line)) {
                        continue;
                    }
                    
                    for pattern in patterns {
                        if (strpos(line, pattern->pattern) === false) {
                            continue;
                        }

                        if (preg_match("/\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}/", line, matches)) {
                            //Always ignore localhost.
                            if (matches[0] == "127.0.0.1") {
                                break;
                            }
                            let data = this->db->get("SELECT * FROM whitelist WHERE ip=:ip", ["ip": matches[0]]);
                            if (!empty(data)) {
                                break;
                            }

                            this->db->execute(
                                "INSERT INTO found_block_patterns
                                    ('ip', 'label', 'category') 
                                VALUES 
                                    (
                                        :ip,
                                        :label,
                                        :category
                                    )",
                                [
                                    "ip": matches[0],
                                    "label": pattern->label,
                                    "category": pattern->category
                                ]
                            );

                            let country = "UNKNOWN";
                            if (this->settings->ip_lookup) {
                                let country = this->getCountry(matches[0]);
                            }

                            let service = "UNKNOWN";
                            let whois = "UNKNOWN";
                            if (this->settings->service_lookup) {
                                let data = this->getService(matches[0]);
                                let whois = data[0];
                                if (data[1]) {
                                    let service = data[1];
                                }
                            }

                            this->db->execute(
                                "INSERT OR REPLACE INTO blacklist
                                    (id, 'ip', 'country', 'whois', 'service') 
                                VALUES 
                                    (
                                        (SELECT id FROM blacklist WHERE ip=:ip),
                                        :ip,
                                        :country,
                                        :whois,
                                        :service
                                    )",
                                [
                                    "ip": matches[0],
                                    "country": country,
                                    "whois": whois,
                                    "service": service
                                ]
                            );
                        }
                    }
                }
            }
        }

        return this->pageTitle("Scanning logs") . "
        <div class='row'>
            <div class='box'>
                <div class='box-title'>
                    <span>Scan complete</span>
                </div>
                <div class='box-body'>
                    <p>All done</p>
                </div>
                <div class='box-footer'>
                    <a href='/dashboard' class='button'>Back to dashboard</a>
                </div>
            </div>
        </div>";
    }

    private function scanWarn(string path)
    {
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
                    <a href='/scan' class='button float-right'>Go</a>
                </div>
            </div>
        </div>";
    }

    private function settings(string path)
    {
        var controller;
        let controller = new Settings();
        return controller->router(path, this->db, this->settings);
    }

    private function users(string path)
    {
        var controller;
        let controller = new Users();
        return controller->router(path, this->db, this->settings);
    }

    private function whitelist(string path)
    {
        var controller;
        let controller = new Whitelist();
        return controller->router(path, this->db, this->settings);
    }
}