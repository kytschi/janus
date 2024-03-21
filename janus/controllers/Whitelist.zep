/**
 * Janus whitelist builder
 *
 * @package     Janus\Controllers\Whitelist
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

class Whitelist extends Controller
{
    public routes = [
        "/whitelist/add": "add",
        "/whitelist/delete/": "delete",
        "/whitelist/edit/": "edit",
        "/whitelist/black/": "blacklist",
        "/whitelist/export": "export",
        "/whitelist/import": "import",
        "/whitelist": "index"
    ];

    public function add(string path)
    {
        var html, status, ip="", ipvsix = false, matches = [];
        let html = this->pageTitle("Create an entry");

        if (isset(_POST["ip"])) {
            let ip = _POST["ip"];
        } elseif (isset(_GET["ip"])) {
            let ip = urldecode(_GET["ip"]);
        }

        if (isset(_POST["save"])) {
            if (!this->validate(_POST, ["ip"])) {
                let html .= this->error();
            } else {
                var country, service, whois, data;
                let country = "UNKNOWN";
                if (this->settings->ip_lookup) {
                    let country = this->getCountry(_POST["ip"]);
                }

                let service = "UNKNOWN";
                let whois = "UNKNOWN";
                if (this->settings->service_lookup) {
                    let data = this->getService(_POST["ip"]);
                    let whois = data[0];
                    if (data[1]) {
                        let service = data[1];
                    }
                }

                if (
                    preg_match(
                        "/([a-f0-9:]+:+)+[a-f0-9]+/",
                        _POST["ip"],
                        matches
                    )
                ) {
                    let ipvsix = true;
                }

                let status = this->db->get(
                    "SELECT id FROM whitelist WHERE ip=:ip",
                    ["ip":  _POST["ip"]]
                );
                if (!empty(status)) {
                    return;
                }

                let status = this->db->execute(
                    "INSERT INTO whitelist
                        (
                            'ip',
                            'country',
                            'service',
                            'whois',
                            'ipvsix',
                            'created_at',
                            'label',
                            'note'
                        ) 
                    VALUES 
                        (
                            :ip,
                            :country,
                            :service,
                            :whois,
                            :ipvsix,
                            :created_at,
                            :label,
                            :note
                        )",
                    [
                        "ip": _POST["ip"],
                        "country": country,
                        "service": service,
                        "whois": whois,
                        "ipvsix": (ipvsix) ? 1 : 0,
                        "created_at": date("Y-m-d"),
                        "label": isset(_POST["label"]) ? _POST["label"] : "",
                        "note": isset(_POST["note"]) ? _POST["note"] : ""
                    ]
                );

                if (!is_bool(status)) {
                    throw new Exception(status);
                }
                unset(_POST["ip"]);
                let html .= this->info("Entry created");
                this->writeCronFiles(true);
            }
        }

        let html .= "
        <form method='POST'>
            <table class='table wfull'>
                <tbody>
                    <tr>
                        <th>IP<span class='required'>*</span></th>
                        <td>
                            <input name='ip' type='text' value='" . (ip ? ip : "") . "'>
                        </td>
                    </tr>
                    <tr>
                        <th>Label</th>
                        <td>
                            <input name='label' type='text' value='" . (isset(_POST["label"]) ? _POST["label"] : "") . "'>
                        </td>
                    </tr>
                    <tr>
                        <th>Note</th>
                        <td>
                            <textarea name='note' rows='6'>" . (isset(_POST["note"]) ? _POST["note"] : "") . "</textarea>
                        </td>
                    </tr>
                </tbody>
                <tfoot>
                    <tr>
                        <td colspan='2'>
                            <button type='submit' name='save' value='save' class='float-right'>save</button>
                        </td>
                    </tr>
                </tfoot>
            </table>
        </form>
        <div class='page-toolbar'>
            <a href='" . this->urlAddKey("/whitelist") . "' class='round icon icon-back' title='Back to list'>&nbsp;</a>
        </div>";

        return html;
    }
    
    public function blacklist(string path)
    {
        var data, status;
        let data = this->db->get(
            "SELECT * FROM whitelist WHERE id=:id",
            [
                "id": this->cleanUrl(path, "/whitelist/black/")
            ]
        );

        if (empty(data)) {
            throw new Exception("Entry not found");
        }

        let status = this->db->execute("DELETE FROM whitelist WHERE id=:id", ["id": data->id]);
        if (!is_bool(status)) {
            throw new Exception(status);
        } 
        
        let status = this->db->get(
            "SELECT id FROM whitelist WHERE ip=:ip",
            ["ip":  _POST["ip"]]
        );
        if (!empty(status)) {
            return;
        }

        let status = this->db->execute(
            "INSERT INTO blacklist
                (id, 'ip', 'country', 'whois', 'service', 'created_at') 
            VALUES 
                (
                    (SELECT id FROM blacklist WHERE ip=:ip),
                    :ip,
                    :country,
                    :whois,
                    :service,
                    :created_at
                )",
            [
                "ip": data->ip,
                "country": data->country,
                "service": data->service,
                "whois": data->whois,
                "created_at": date("Y-m-d")
            ]
        );
        if (!is_bool(status)) {
            throw new Exception(status);
        } 

        this->redirect(this->urlAddKey("/whitelist?blacklist=true"));
    }

    public function delete(string path)
    {
        var data, status;
        let data = this->db->get(
            "SELECT * FROM whitelist WHERE id=:id",
            [
                "id": this->cleanUrl(path, "/whitelist/delete/")
            ]
        );

        if (empty(data)) {
            throw new Exception("Entry not found");
        }

        let status = this->db->execute("DELETE FROM whitelist WHERE id=:id", ["id": data->id]);
        if (!is_bool(status)) {
            throw new Exception(status);
        }

        this->redirect(this->urlAddKey("/whitelist?deleted=true"));
    }

    public function edit(string path)
    {
        var html, data, status;
        let html = this->pageTitle("Whitelist IP");

        let data = this->db->get(
            "SELECT * FROM whitelist WHERE id=:id",
            [
                "id": this->cleanUrl(path, "/whitelist/edit/")
            ]
        );

        if (empty(data)) {
            throw new Exception("Entry not found");
        }

        if (isset(_POST["save"])) {
            let status = this->db->execute(
                "UPDATE whitelist SET
                    label=:label,
                    note=:note
                WHERE
                    id=:id",
                [
                    "id": data->id,
                    "label": isset(_POST["label"]) ? _POST["label"] : "",
                    "note": isset(_POST["note"]) ? _POST["note"] : ""
                ]
            );

            if (!is_bool(status)) {
                throw new Exception(status);
            }
            let html .= this->info("Entry updated");
        }

        let html .= "
        <form method='POST'>
            <table class='table wfull'>
                <tbody>
                    <tr>
                        <th>IP</th>
                        <td>" . data->ip . "</td>
                    </tr>
                    <tr>
                        <th>Label</th>
                        <td>
                            <input name='label' type='text' value='" . (isset(_POST["label"]) ? _POST["label"] : data->label) . "'>
                        </td>
                    </tr>
                    <tr>
                        <th>Note</th>
                        <td>
                            <textarea name='note' rows='6'>" . (isset(_POST["note"]) ? _POST["note"] : data->note) . "</textarea>
                        </td>
                    </tr>
                    <tr>
                        <th>Created at</th>
                        <td>" . (data->created_at ? Date("d/m/Y", strtotime(data->created_at)) : "Unknown") . "</td>
                    </tr>
                    <tr>
                        <th>Country</th>
                        <td>" . data->country . "</td>
                    </tr>
                    <tr>
                        <th>Service</th>
                        <td>" . data->service . "</td>
                    </tr>
                </tbody>
                <tfoot>
                    <tr>
                        <td colspan='2'>
                            <button type='submit' name='save' value='save' class='float-right'>save</button>
                        </td>
                    </tr>
                </tfoot>
            </table>
        </form>
        <div class='page-toolbar'>
            <a href='" . this->urlAddKey("/whitelist") . "' class='round icon icon-back' title='Back to list'>&nbsp;</a>
            <a href='" . this->urlAddKey("/whitelist/delete/" . data->id) . "' class='round icon icon-delete' title='Delete the entry'>&nbsp;</a>
            <a href='" . this->urlAddKey("/whitelist/black/" . data->id) . "' class='round icon icon-blacklist align-right' title='Blacklist the entry'>&nbsp;</a>
        </div>
        <table class='table wfull'>
            <tbody>
                <tr>
                    <th colspan='2'>Whois</th>
                </tr>
                <tr>
                    <td colspan='2' class='log-output'>" . data->whois . "</td>
                </tr>
            </tbody>
        </table>
        <h2><span>Matching patterns</span></h2>";

        let data = this->db->all(
            "SELECT
                main.*,
                (
                    SELECT 
                        count(id) 
                    FROM 
                        found_block_patterns AS sub 
                    WHERE 
                        sub.ip=main.ip AND sub.pattern=main.pattern 
                    GROUP BY sub.pattern
                ) AS total 
            FROM 
                found_block_patterns AS main
            WHERE 
                main.ip=:ip GROUP BY main.pattern 
            ORDER BY total DESC, main.label ASC",
            [
                "ip": data->ip
            ]
        );
        if (count(data)) {
            let html .= "<table class='table wfull'>
                <thead>
                    <tr>
                        <th>Pattern</th>
                        <th width='200px'>Matches</th>
                        <th>Label</th>
                        <th>Category</th>
                    </tr>
                </thead>
                <tbody>";
            var item;
            for item in data {
                let html .= "<tr>
                    <td>" . item->pattern . "</td>
                    <td>" . item->total . "</td>
                    <td>" . item->label . "</td>
                    <td>" . item->category . "</td>
                </tr>";
            }
            let html .= "</tbody></table>";
        } else {
            let html .= "<h2><span>No patterns found</span></h2>";
        }

        return html;
    }

    public function export(string path)
    {
        var item, data, iLoop = 0, query, vars = [], head, colon = false;

        let query = "SELECT * FROM whitelist";
        if (isset(_GET["i"])) {
            let query .= " WHERE ip=:query";
            let vars["query"] = urldecode(_GET["i"]);
        }
        let query .= " ORDER BY ip";

        let data = this->db->all(query, vars);
        if (empty(data)) {
            throw new Exception("No whitelist to export");
        }
        
        header("Content-Type: application/sql");
        header("Content-Disposition: attachment; filename=janus_" . date("Y_m_d_H_i_s") . ".jim");
        let head = "REPLACE INTO whitelist (`id`, `ip`, `country`, `whois`, `service`, `created_at`, `ipvsix`, `note`, `label`) VALUES";
        echo head;
        for iLoop, item in data {
            echo "\n(
                (SELECT id FROM whitelist AS src WHERE ip=\"" . item->ip . "\" LIMIT 1), 
                \"" . addslashes(item->ip) . "\", 
                \"" . addslashes(item->country) . "\", 
                \"" . addslashes(item->whois) . "\",
                \"" . addslashes(item->service) . "\", 
                \"" . addslashes(item->created_at) . "\", 
                \"" . addslashes(item->ipvsix) . "\",
                \"" . addslashes(item->note) . "\",
                \"" . addslashes(item->label) . "\"
            )";
            if (!fmod(iLoop + 1, 20)) {
                let colon = true;
                echo ";/*ENDJIM*/";
                echo head;
            } elseif (iLoop < count(data) - 1) {
                let colon = false;
                echo ",";
            }
        }
        if (!colon) {
            echo ";/*ENDJIM*/";
        }
        die();
    }

    public function index(string path)
    {
        var html, data, query, vars=[], page = 1, count, where = "", filter = "";
        let html = this->pageTitle("Whitelist IPs");

        if (isset(_GET["deleted"])) {
            let html .= this->info("Entry deleted and will be removed from whitelist");
        } elseif (isset(_GET["blacklist"])) {
            let html .= this->info("Entry has been marked for blacklisting");
        }

        let query = "SELECT 
            whitelist.*,
            (SELECT id FROM blacklist WHERE blacklist.ip=whitelist.ip) AS blacklisted 
        FROM whitelist";
        
        if (isset(_GET["page"])) {
            let page = intval(_GET["page"]);
            if (empty(page)) {
                let page = 1;
            }
        }
        
        let count = "SELECT count(id) AS total FROM whitelist";
        if (isset(_POST["q"])) {
            let where .= " WHERE whitelist.ip=:query";
            let vars["query"] = _POST["q"];
            let filter = "?i=" . urlencode(_POST["q"]);
        }

        let count = this->db->get(count . where, vars);
        let count = count->total;

        let query .= where . " ORDER BY whitelist.ip, whitelist.country LIMIT " . page . ", " . this->per_page;

        let data = this->db->all(query, vars);
            
        if (count) {
            let html .= "
                <form action='" . this->urlAddKey("/whitelist") . "' method='post'>
                    <table class='table wfull'>
                        <tr>
                            <th>IP<span class='required'>*</span></th>
                            <td>
                                <input name='q' type='text' value='" . (isset(_POST["q"]) ? _POST["q"]  : ""). "'>
                            </td>
                        </tr>
                        <tfoot>
                            <tr>
                                <td colspan='2'>
                                    <button type='submit' name='search' value='search' class='float-right'>search</button>";
            if (isset(_POST["q"])) {
                let html .= "<a href='" . this->urlAddKey("/whitelist") . "' class='float-right button'>clear</a>";
            }
            let html .= "</td>
                            </tr>
                        </tfoot>
                    </table>
                </form>";

            let html .= "<table class='table wfull'>
                <thead>
                    <tr>
                        <th width='200px'>IP</th>
                        <th>Info</th>
                        <th class='buttons' width='140px'>
                            <a href='" . this->urlAddKey("/whitelist/add") . "' class='mini icon icon-add' title='Create an entry'>&nbsp;</a>
                        </th>
                    </tr>
                </thead>
                <tbody>";
            var item;
            for item in data {
                let html .= "<tr>
                    <td>
                        <p style='margin-bottom:0 !important'>" . item->ip . "</p>".
                        (!empty(item->label) ? "<p style='margin-top:0 !important'><strong>" . item->label . "</strong></p>" : "") .
                        "<p style='margin:0 !important;float:left;width:100%;'>
                            <span class='pill'>" . (item->ipvsix ? "IPv6" : "IPv4") . "</span>
                        " . (item->blacklisted ? "<span class='pill pill-red'>blacklisted</span>" : "") .
                        "</p>" .
                    "</td>
                    <td>" . (item->country != "UNKNOWN" ? "<p>" . item->country . "</p>" : "") .
                        "<p>" . item->service . "</p></td>
                    <td class='buttons'>
                        <a href='" . this->urlAddKey("/whitelist/edit/" . item->id) . "' class='mini icon icon-edit' title='View/Edit the entry'>&nbsp;</a>
                        <a href='" . this->urlAddKey("/whitelist/black/" . item->id) . "' class='mini icon icon-blacklist' title='Blacklist the entry'>&nbsp;</a>
                        <a href='" . this->urlAddKey("/whitelist/delete/" . item->id) . "' class='mini icon icon-delete' title='Delete the entry'>&nbsp;</a>
                    </td>
                </tr>";
            }
            let html .= "</tbody></table>";
            let html .= this->pagination(count, page, "/whitelist");
        } else {
            let html .= "<h2><span>Nothing found</span></h2>";
            if (isset(_POST["q"])) {
                let html .= "<p><a href='" . this->urlAddKey("/whitelist") . "' class='button'>clear search</a></p>";
            }
        }

        let html .= "<div class='page-toolbar'>
            <a href='" . this->urlAddKey("/whitelist/add") . "' class='round icon icon-add'>&nbsp;</a>";
        if (count) {
            let html .= "<a href='" . this->urlAddKey("/whitelist/export" . filter) . "' class='round icon icon-export' title='Export Janus blacklist'>&nbsp;</a>";
        }
        let html .= "<a href='" . this->urlAddKey("/whitelist/import") . "' class='round icon icon-import' title='Import Janus blacklist'>&nbsp;</a>
        </div>";

        return html;
    }
}