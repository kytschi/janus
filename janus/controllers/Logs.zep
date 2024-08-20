/**
 * Janus logs
 *
 * @package     Janus\Controllers\Logs
 * @author 		Mike Welsh
 * @copyright   2023 Mike Welsh
 * @version     0.0.1
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
namespace Janus\Controllers;

use Janus\Controllers\Controller;
use Janus\Exceptions\Exception;

class Logs extends Controller
{
    public routes = [
        "/logs/add": "add",
        "/logs/delete/": "delete",
        "/logs/edit/": "edit",
        "/logs": "index"
    ];

    private highlights = [];

    public function add(string path)
    {
        var html, status;
        let html = this->pageTitle("Creating an entry");

        if (isset(_POST["save"])) {
            let status = this->db->execute(
                "INSERT INTO logs (log) VALUES (:log)",
                [
                    "log": _POST["log"]
                ]
            );

            if (!is_bool(status)) {
                throw new Exception(status);
            }
            let html .= this->info("Entry created");
        }

        let html .= "
        <form method='POST'>
            <table class='table wfull'>
                <tbody>
                    <tr>
                        <th>Log</th>
                        <td>
                            <input class='form-input' name='log' value=''>
                        </td>
                    </tr>
                </tbody>
                <tfoot>
                    <tr>
                        <td colspan='2'>
                            <button name='save' value='save' class='float-right' type='submit'>Save</button>
                        </td>
                    </tr>
                </tfoot>
            </table>
        </form>
        <div class='page-toolbar'>
            <a href='" . this->urlAddKey("/logs") . "' class='round icon icon-back' title='Back to list'>&nbsp;</a>
        </div>";        

        return html;
    }

    public function delete(string path)
    {
        var data, status;
        let data = this->db->get(
            "SELECT * FROM logs WHERE id=:id",
            [
                "id": this->cleanUrl(path, "/logs/delete/")
            ]
        );

        if (empty(data)) {
            throw new Exception("Entry not found");
        }

        let status = this->db->execute("DELETE FROM logs WHERE id=:id", ["id": data->id]);
        if (!is_bool(status)) {
            throw new Exception(status);
        } 
        this->redirect(this->urlAddKey("/logs?deleted=true"));
    }

    public function edit(string path)
    {
        var html, data, status;
        let html = this->pageTitle("Editing the log");

        let data = this->db->get(
            "SELECT * FROM logs WHERE id=:id",
            [
                "id": this->cleanUrl(path, "/logs/edit/")
            ]
        );

        if (empty(data)) {
            throw new Exception("Entry not found");
        }

        if (isset(_POST["save"])) {
            let status = this->db->execute(
                "UPDATE logs SET log=:log WHERE id=:id",
                [
                    "id": data->id,
                    "log": _POST["log"]
                ]
            );

            if (!is_bool(status)) {
                throw new Exception(status);
            } 

            let data->log = _POST["log"];
            let html .= this->info("Entry updated");
        }

        let html .= "
        <form method='POST'>
            <table class='table wfull'>
                <tbody>
                    <tr>
                        <th>Log</th>
                        <td>
                            <input class='form-input' name='log' value='" . data->log . "'>
                        </td>
                    </tr>
                </tbody>
                <tfoot>
                    <tr>
                        <td colspan='2'>
                            <button name='save' value='save' class='float-right' type='submit'>Save</button>
                        </td>
                    </tr>
                </tfoot>
            </table>
        </form>
        <div class='page-toolbar'>
            <a href='" . this->urlAddKey("/logs") . "' class='round icon icon-back' title='Back to list'>&nbsp;</a>
            <a href='" . this->urlAddKey("/logs/delete/" . data->id) . "' class='round icon icon-delete' title='Delete the entry'>&nbsp;</a>
        </div>";

        var dir, logs, log, line, lines, iLoop=0,
            found, found_ips, found_ip, 
            buttons, patterns, pattern;
        let dir = shell_exec("ls " . data->log);
        if (!empty(dir)) {
            let logs = explode("\n", dir);

            if (!empty(logs)) {
                let patterns = this->db->all("SELECT * FROM block_patterns");

                let html .= "<h2><span>The log</span></h2>
                <table class='table wfull'>
                    <tbody>";

                for log in logs {
                    if (empty(log)) {
                        continue;
                    }

                    let lines = explode("\n", file_get_contents(log));
                    if (empty(lines)) {
                        continue;
                    }

                    for iLoop, line in lines {
                        if (empty(line)) {
                            continue;
                        }
                        
                        let buttons = "";
                        let this->highlights = [
                            "danger": [],
                            "info": [],
                            "success": [],
                            "warning": []
                        ];

                        let found = false;
                        
                        for pattern in patterns {
                            if (strpos(strtolower(line), strtolower(pattern->pattern)) !== false) {
                                let found = pattern;
                                let this->highlights["danger"][] = pattern->pattern;
                                break;
                            }
                        }

                        let found_ips = this->getIPVSIX(line, false);
                        if (found_ips) {
                            for pattern in found_ips {
                                let buttons .= this->genHTML(pattern);
                            }
                        }
                        let found_ip = this->getIP(line, false);
                        if (found_ip) {
                            for pattern in found_ip {
                                let buttons .= this->genHTML(pattern);
                            }
                        }

                        let html .= "<tr><td><p class='log-output'>" .
                            this->highlight(htmlentities(line), this->highlights) . 
                            "</p>";

                        if (found) {
                            let html .= "<a 
                                    class='mini icon icon-patterns active' 
                                    title='Found pattern: ". found->pattern . "'
                                    href='" . this->urlAddKey("/patterns/edit/" . found->id) . "'>
                                    &nbsp;
                                </a>";
                        } else {
                            let html .= "<a title='Create a pattern from line' 
                                href='" .this->urlAddKey("/patterns/add?log=" . data->id . "&line=" . iLoop) ."'
                                class='mini icon icon-patterns'>&nbsp;</a>";
                        }

                        let html .= buttons . "</td></tr>";
                    }
                }

                let html .= "</tbody></table>";
            } else {
                let html .= "<h2><span>Failed to read the log</span></h2>";
            }
        } else {
            let html .= "<h2><span>Failed to read the log</span></h2>";
        }
    
        return html;
    }

    private function genHTML(ip)
    {
        var found, html = "", no_match = true;

        let found = this->db->get(
            "SELECT * FROM blacklist WHERE ip=:ip",
            [
                "ip": ip
            ]
        );
        if (found) {
            let html .= "<a 
                    class='mini icon icon-blacklist active' 
                    title='Found blacklisted IP: " . found->ip . "' 
                    href='" . this->urlAddKey("/blacklist/edit/" . found->id) . "'>
                    &nbsp;
                </a>";
            let this->highlights["danger"][] = found->ip;
            let no_match = false;
        } else {
            let html .= "<a 
                title='Create a blacklist entry for IP: " . ip . "' 
                href='" .this->urlAddKey("/blacklist/add?ip=" . urlencode(ip)) . "'
                class='mini icon icon-blacklist'>&nbsp;</a>";
        }

        let found = this->db->get(
            "SELECT * FROM whitelist WHERE ip=:ip",
            [
                "ip": ip
            ]
        );
        if (found) {
            let html .= "<a 
                    class='mini icon icon-whitelist active' 
                    title='Found whitelisted IP: " . (found->label ? found->label : found->ip) . "' 
                    href='" . this->urlAddKey("/whitelist/edit/" . found->id) . "'>
                    &nbsp;
                </a>";
            if (no_match) {
                let this->highlights["success"][] = found->ip;
                let no_match = false;
            }
        } else {
            let html .= "<a 
                title='Create a whitelist entry for IP: " . ip . "' 
                href='" .this->urlAddKey("/whitelist/add?ip=" . urlencode(ip)) . "'
                class='mini icon icon-whitelist'>&nbsp;</a>";
        }

        let found = this->db->get(
            "SELECT * FROM watchlist WHERE ip=:ip",
            [
                "ip": ip
            ]
        );
        if (found) {
            let html .= "<a 
                    class='mini icon icon-watchlist active' 
                    title='Found watchlist IP: " . found->ip . "' 
                    href='" . this->urlAddKey("/watchlist/edit/" . found->id) . "'>
                    &nbsp;
                </a>";
            if (no_match) {
                let this->highlights["warning"][] = found->ip;
                let no_match = false;
            }
        } else {
            let html .= "<a 
                title='Create a watchlist entry for IP: " . ip . "' 
                href='" .this->urlAddKey("/watchlist/add?ip=" . urlencode(ip)) . "'
                class='mini icon icon-watchlist'>&nbsp;</a>";
        }

        if (no_match) {
            let this->highlights["info"][] = ip;
        }

        return html;
    }

    private function highlight(line, highlights)
    {
        var data, highlight, style;

        for style, data in highlights {
            for highlight in data {
                let line = str_replace(
                    highlight,
                    "<span class='text-" . style . "'>" . highlight . "</span>",
                    line
                );
            }
        }

        return line;
    }

    public function index(string path)
    {
        var html, data, query, vars=[];
        let html = this->pageTitle("Logs to watch");

        if (isset(_GET["deleted"])) {
            let html .= this->info("Entry deleted");
        }

        let query = "SELECT * FROM logs";
        if (isset(_POST["q"])) {
            let query .= " WHERE log LIKE :query";
            let vars["query"] = "%" . _POST["q"] . "%";
        }
        let query .= " ORDER BY log";

        let data = this->db->all(query, vars);
        if (count(data)) {
            let html .= "
                <form action='" . this->urlAddKey("/logs") . "' method='post'>
                    <table class='table wfull'>
                        <tr>
                            <th>Log<span class='required'>*</span></th>
                            <td>
                                <input name='q' type='text' value='" . (isset(_POST["q"]) ? _POST["q"]  : ""). "'>
                            </td>
                        </tr>
                        <tfoot>
                            <tr>
                                <td colspan='2'>
                                    <button type='submit' name='search' value='search' class='float-right'>search</button>";
            if (isset(_POST["q"])) {
                let html .= "<a href='" . this->urlAddKey("/logs") . "' class='float-right button'>clear</a>";
            }
            let html .= "</td>
                            </tr>
                        </tfoot>
                    </table>
                </form>";

            let html .= "<table class='table wfull'>
                <thead>
                    <tr>
                        <th>Log</th>
                        <th class='buttons' width='120px'>
                            <a href='" . this->urlAddKey("/logs/add") . "' class='mini icon icon-add' title='Create an entry'>&nbsp;</a>
                        </th>
                    </tr>
                </thead>
                <tbody>";
            var item;
            for item in data {
                let html .= "<tr>
                    <td>" . item->log . "</td>
                    <td class='buttons'>
                        <a href='" . this->urlAddKey("/logs/edit/" . item->id) . "' class='mini icon icon-edit' title='View/Edit the entry'>&nbsp;</a>
                        <a href='" . this->urlAddKey("/logs/delete/" . item->id) . "' class='mini icon icon-delete' title='Delete the entry'>&nbsp;</a>
                    </td>
                </tr>";
            }
            let html .= "</tbody></table>";
        } else {
            let html .= "<h2><span>No logs found</span></h2>";
            if (isset(_POST["q"])) {
                let html .= "<p><a href='" . this->urlAddKey("/logs") . "' class='button'>clear search</a></p>";
            }
            let html .= "<p><a href='" . this->urlAddKey("/logs/add") . "' class='round icon icon-add'>&nbsp;</a></p>";
        }
        return html;
    }
}