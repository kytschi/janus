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

use Janus\Exceptions\Exception;
use Janus\Helpers\Captcha;
use Janus\Ui\Head;

class Janus
{
    private cfg;
    private cfg_file;

    public function __construct(string cfg_file)
    {
        if (!file_exists(cfg_file)) {
            throw new Exception("Failed to load the config file");
        }

        let this->cfg_file = cfg_file;

        var cfg;
        let cfg = new \stdClass();
        let cfg = json_decode(file_get_contents(cfg_file), false, 512, JSON_THROW_ON_ERROR);

        if (empty(cfg)) {
            throw new Exception("Invalid config file");
        }

        if (is_object(cfg->ip_countries)) {
            let cfg->ip_countries = get_object_vars(cfg->ip_countries);
        } else {
            let cfg->ip_countries = [];
        }

        if (is_object(cfg->stat_patterns)) {
            let cfg->stat_patterns = get_object_vars(cfg->stat_patterns);
        }  else {
            let cfg->stat_patterns = [];
        }

        let this->cfg = cfg;

        var property, properties = [
            "iptables_bin",
            "iptables_cfg_folder",
            "iptables_cfg_file_v4",
            "ip_lookup",
            "logs",
            "block_patterns_folder",
            "block_patterns",
            "access"
        ];

        for property in properties {
            if (!property_exists(this->cfg, property)) {
                throw new Exception("Invalid config file");
            }

            if (empty(this->cfg->{property})) {
                throw new Exception("Invalid config file, check `" . property . "`");
            }
        }

        if (session_status() === 1) {
            session_name("janus");
            session_start();
        }

        var routes = [
            "/dashboard": "dashboard",
            "/scan": "scan",
            "/scan-warn": "scanWarn",
            "/the-secure-door": "login"
        ];

        var code = 200, path, parsed, output = "", route, logged_in = false;

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

        if (!empty(routes[path])) {
            let route = routes[path];
            let output = this->{route}();
        }

        if (empty(output)) {
            let code = 404;
            let output = this->notFound();
        }

        this->head(code);
        echo output;
        this->footer(logged_in);
    }

    private function dashboard()
    {
        return "<h1>Dashboard</h1>
        <div class='page-toolbar'>
            <a href='/dashboard' class='round icon icon-dashboard' title='Dashboard'>&nbsp;</a>
            <a href='/scan-warn' class='round icon icon-events' title='Scan the logs'>&nbsp;</a>
        </div>
        <div class='row'>" .
            this->patternsUI() .
            (this->cfg->ip_lookup === true ? this->ipCountriesUI() : "") . 
        "</div>";
    }

    private function error(string message = "Missing required fields")
    {
        return "<div class='error box wfull'>
        <div class='box-title'>
            <span>Error</span>
        </div>
        <div class='box-body'>
            <p>" . message . "</p>
        </div></div>";
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
        var height = 200, labels = [], totals = [], colours = [];

        if (!empty(this->cfg->ip_countries)) {
            var label, value;
            let height = count(this->cfg->ip_countries) * 30;

            for label, value in this->cfg->ip_countries {
                let labels[] = "\"" . label . "\"";
                let totals[] = value;
                let colours[] = "\"#" . substr(md5(label), 3, 6) . "\"";
            }

            if (height < 200) {
                let height = 200;
            }
        }

        let labels = implode(",", labels);
        let totals = implode(",", totals);
        let colours = implode(",", colours);

        return  "<div class='box'>
        <div class='box-title'>
            <span>IP source countries</span>
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
                                label: 'countries',
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

    private function login()
    {
        var html, captcha;
        let captcha = new Captcha();

        let html = "<h1>Login</h1>";

        if (!empty(_POST)) {
            if (isset(_POST["login"])) {
                if (!this->validate(_POST, ["u", "p", "janus_captcha"])) {
                    let html .= this->error("Missing required inputs");
                } else {
                    if (!captcha->validate()) {
                        let html .= this->error("Invalid captcha");
                    } else {
                        var user;
                        let user = _POST["u"];
                        if (property_exists(this->cfg->access, user)) {
                            if (password_verify(_POST["p"], this->cfg->access->{user})) {
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

        let html .= "<form method='post'><div id='login' class='box'>
            <div class='box-body'>
                <div class='input-group'>
                    <span>username<span class='required'>*</span></span>
                    <input type='text' name='u' placeholder='what is your username?'>
                </div>
                <div class='input-group'>
                    <span>password<span class='required'>*</span></span>
                    <input type='password' name='p' placeholder='your secret password please'>
                </div>
                <div class='input-group'><span>captcha<span class='required'>*</span></span>" . captcha->draw() . "</div>
            </div>
            <div class='box-footer'>
                <button type='submit' name='login'>login</button>
            </div>
        </div></form>";

        return html;
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

    private function patternsUI()
    {
        var height = 200, labels = [], totals = [], colours = [];

        if (!empty(this->cfg->stat_patterns)) {
            var label, value;
            let height = count(this->cfg->stat_patterns) * 30;

            for label, value in this->cfg->stat_patterns {
                let labels[] = "\"" . label . "\"";
                let totals[] = value;
                let colours[] = "\"#" . substr(md5(label), 3, 6) . "\"";
            }

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

    private function redirect(string url)
    {
        header("Location: " . url);
        die();
    }

    private function getCountry(ip)
    {
        var output, splits;
        let output = shell_exec("geoiplookup " . ip);
        if (output) {
            let splits = explode(":", output);
            let splits = explode(",", splits[count(splits) - 1]);
            unset(splits[0]);
            return trim(implode(",", splits));
        }
        return null;
    }

    private function scan()
    {
        if (empty(this->cfg->logs)) {
            throw new Exception("No log folders defined to scan");
        }

        if (empty(this->cfg->block_patterns)) {
            throw new Exception("No block patterns defined to scan for");
        }

        var cfg;
        let cfg = this->cfg;
        if (!property_exists(cfg, "blacklist")) {
            let cfg->blacklist = [];
        }

        //Always ignore localhost.
        let cfg->whitelist[] = "127.0.0.1";

        var folder, dir, logs, log, lines, line, pattern, patterns = [], matches, err, country;

        for log in this->cfg->block_patterns {
            let lines = get_object_vars(
                json_decode(
                    file_get_contents(rtrim(cfg->block_patterns_folder, "/") . "/" .  log . ".json"),
                    false,
                    512,
                    JSON_THROW_ON_ERROR
                )
            );
            
            let patterns = array_merge(patterns, lines);
        }

        for folder in cfg->logs {
            let dir = shell_exec("ls " . folder);
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
                    
                    for pattern, dir in patterns {
                        if (strpos(line, pattern) === false) {
                            continue;
                        }

                        if (preg_match("/\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}/", line, matches)) {
                            if (in_array(cfg->whitelist, matches[0])) {
                                break;
                            }
                            if (!in_array(cfg->blacklist, matches[0])) {
                                let cfg->blacklist[] = matches[0];

                                if (cfg->ip_lookup) {
                                    let country = this->getCountry(matches[0]);
                                    if (country) {
                                        if (isset(cfg->ip_countries[country])) {
                                            let cfg->ip_countries[country] = intval(cfg->ip_countries[country]) + 1;
                                        } else {
                                            let cfg->ip_countries[country] = 1;
                                        }
                                    }
                                }
                            }
                        }

                        if (isset(cfg->stat_patterns[dir])) {
                            let cfg->stat_patterns[dir] = intval(cfg->stat_patterns[dir]) + 1;
                        } else {
                            let cfg->stat_patterns[dir] = 1;
                        }
                    }
                }
            }
        }

        try {
            if (!file_put_contents(this->cfg_file, json_encode(cfg))) {
                throw new Exception("make sure the web user has permissions to write to the cfg");
            }
            let this->cfg = cfg;
        } catch \Exception, err {
            throw new Exception("Failed to save the cfg, " . strtolower(err->getMessage()));
        }

        return "<h1>Scanning logs</h1>
            <div class='box wfull'>
            <div class='box-title'>
                <span>Scan complete</span>
            </div>
            <div class='box-body'>
                <a href='/dashboard' class='button'>Back to dashboard</a>
            </div></div>";
    }

    private function scanWarn()
    {
        return "<h1>Scan logs</h1>
            <div class='box wfull'>
            <div class='box-title'>
                <span>Scan the logs</span>
            </div>
            <div class='box-body'>
                <p>Scanning can take sometime</p>
                <a href='/scan' class='button'>Go</a>
            </div></div>";
    }

    private function validate(array data, array checks)
    {
        var iLoop = 0;
        while (iLoop < count(checks)) {
            if (!isset(data[checks[iLoop]])) {
                return false;
            }
            
            if (empty(data[checks[iLoop]])) {
                return false;
            }
            let iLoop = iLoop + 1;
        }
        return true;
    }
}