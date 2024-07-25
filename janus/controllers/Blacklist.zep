/**
 * Janus blacklist builder
 *
 * @package     Janus\Controllers\Blacklist
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

class Blacklist extends Controller
{
    public routes = [
        "/blacklist/add": "add",
        "/blacklist/delete/": "delete",
        "/blacklist/edit/": "edit",
        "/blacklist/white/": "whitelist",
        "/blacklist/export": "export",
        "/blacklist/import": "import",
        "/blacklist": "index"
    ];

    public function add(string path)
    {
        var html, status, ip="", ipvsix = false, matches = [];
        let html = this->pageTitle("Blacklist an IP");

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

                let data = this->db->get("SELECT id FROM blacklist WHERE ip=:ip", ["ip": ip]);
                if (!empty(data)) {
                    let html .= this->info("Entry already created");
                } else {
                    let status = this->db->execute(
                        "INSERT INTO blacklist
                            (
                                'ip',
                                'country',
                                'service',
                                'whois',
                                'ipvsix',
                                'created_at',
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
                                :note
                            )",
                        [
                            "ip": _POST["ip"],
                            "country": country,
                            "service": service,
                            "whois": whois,
                            "ipvsix": (ipvsix) ? 1 : 0,
                            "created_at": date("Y-m-d"),
                            "note": isset(_POST["note"]) ? _POST["note"] : ""
                        ]
                    );

                    if (!is_bool(status)) {
                        throw new Exception(status);
                    }
                    unset(_POST["ip"]);
                    let ip = "";
                    let html .= this->info("Entry created");
                    this->writeCronFiles(true);
                }
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
            <a href='" . this->urlAddKey("/blacklist") . "' class='round icon icon-back' title='Back to list'>&nbsp;</a>
        </div>";

        return html;
    }

    public function delete(string path)
    {
        var data, status;
        let data = this->db->get(
            "SELECT * FROM blacklist WHERE id=:id",
            [
                "id": this->cleanUrl(path, "/blacklist/delete/")
            ]
        );

        if (empty(data)) {
            throw new Exception("Entry not found");
        }

        let status = this->db->execute("DELETE FROM blacklist WHERE id=:id", ["id": data->id]);
        if (!is_bool(status)) {
            throw new Exception(status);
        } 
        
        this->redirect(this->urlAddKey("/blacklist?deleted=true"));
    }

    public function edit(string path)
    {
        var html, data, status;
        let html = this->pageTitle("Blacklisted IP");

        let data = this->db->get(
            "SELECT * FROM blacklist WHERE id=:id",
            [
                "id": this->cleanUrl(path, "/blacklist/edit/")
            ]
        );

        if (empty(data)) {
            throw new Exception("Entry not found");
        }

        if (isset(_POST["save"])) {
            let status = this->db->execute(
                "UPDATE blacklist SET
                    note=:note
                WHERE
                    id=:id",
                [
                    "id": data->id,
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
            <a href='" . this->urlAddKey("/blacklist") . "' class='round icon icon-back' title='Back to list'>&nbsp;</a>
            <a href='" . this->urlAddKey("/blacklist/delete/" . data->id) . "' class='round icon icon-delete' title='Delete the entry'>&nbsp;</a>
            <a href='" . this->urlAddKey("/blacklist/white/". data->id) . "' class='round icon icon-whitelist align-right' title='Whitelist the entry'>&nbsp;</a>
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

        let query = "SELECT * FROM blacklist";
        if (isset(_GET["i"])) {
            let query .= " WHERE ip=:query";
            let vars["query"] = urldecode(_GET["i"]);
        }
        let query .= " ORDER BY ip";

        let data = this->db->all(query, vars);
        if (empty(data)) {
            throw new Exception("No blacklist to export");
        }
        
        header("Content-Type: application/sql");
        header("Content-Disposition: attachment; filename=janus_" . date("Y_m_d_H_i_s") . ".jim");
        let head = "REPLACE INTO blacklist (`id`, `ip`, `country`, `whois`, `service`, `created_at`, `ipvsix`, `note`) VALUES";
        echo head;
        for iLoop, item in data {
            echo "\n(
                (SELECT id FROM blacklist AS src WHERE ip=\"" . item->ip . "\" LIMIT 1), 
                \"" . addslashes(item->ip) . "\", 
                \"" . addslashes(item->country) . "\", 
                \"" . addslashes(item->whois) . "\",
                \"" . addslashes(item->service) . "\", 
                \"" . addslashes(item->created_at) . "\", 
                \"" . addslashes(item->ipvsix) . "\",
                \"" . addslashes(item->note) . "\"
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
        let html = this->pageTitle("Blacklisted IPs");

        if (isset(_GET["deleted"])) {
            let html .= this->info("Entry deleted and will be removed from blacklist");
        } elseif (isset(_GET["whitelist"])) {
            let html .= this->info("Entry has been marked for whitelisting");
        }

        if (isset(_GET["page"])) {
            let page = intval(_GET["page"]);
            if (empty(page)) {
                let page = 1;
            }
        }
        
        let count = "SELECT count(id) AS total FROM blacklist";
        let query = "
            SELECT 
                blacklist.*,
                (
                    SELECT 
                        count(found_block_patterns.id) 
                    FROM 
                        found_block_patterns 
                    WHERE 
                        found_block_patterns.ip=blacklist.ip
                ) AS patterns,
                (SELECT id FROM whitelist WHERE whitelist.ip=blacklist.ip) AS whitelisted  
                FROM blacklist";
        if (isset(_POST["q"])) {
            let where .= " WHERE blacklist.ip=:query";
            let vars["query"] = _POST["q"];
            let filter = "?i=" . urlencode(_POST["q"]);
        }

        let count = this->db->get(count . where, vars);
        let count = count->total;

        let query .= where . " ORDER BY patterns DESC, blacklist.ip ASC LIMIT " . ((page - 1) * this->per_page) . ", " . this->per_page;

        let data = this->db->all(query, vars);
        if (count) {
            let html .= "
                <form action='" . this->urlAddKey("/blacklist") . "' method='post'>
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
                let html .= "<a href='" . this->urlAddKey("/blacklist") . "' class='float-right button'>clear</a>";
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
                        <th>Patterns</th>
                        <th>Info</th>
                        <th class='buttons' width='140px'>
                            <a href='" . this->urlAddKey("/blacklist/add") . "' class='mini icon icon-add' title='Create an entry'>&nbsp;</a>
                        </th>
                    </tr>
                </thead>
                <tbody>";
            var item;
            for item in data {
                let html .= "<tr>
                    <td>" . item->ip .
                        "<p style='margin:0 !important'><span class='pill'>" . (item->ipvsix ? "IPv6" : "IPv4") . "</span>
                        " . (item->whitelisted ? "<span class='pill pill-red'>whitelisted</span>" : "") . "</p>
                    </td>
                    <td>" . item->patterns . "</td>
                    <td>" . (item->country != "UNKNOWN" ? "<p>" . item->country . "</p>" : "") .
                        "<p>" . item->service . "</p></td>
                    <td class='buttons'>
                        <a href='" . this->urlAddKey("/blacklist/edit/" . item->id) . "' class='mini icon icon-edit' title='View/Edit the entry'>&nbsp;</a>
                        <a href='" . this->urlAddKey("/blacklist/white/" . item->id) . "' class='mini icon icon-whitelist' title='Whitelist the entry'>&nbsp;</a>
                        <a href='" . this->urlAddKey("/blacklist/delete/" . item->id) . "' class='mini icon icon-delete' title='Delete the entry'>&nbsp;</a>
                    </td>
                </tr>";
            }
            let html .= "</tbody></table>";
            let html .= this->pagination(count, page, "/blacklist");
        } else {
            let html .= "<h2><span>Nothing found</span></h2>";
            if (isset(_POST["q"])) {
                let html .= "<p><a href='" . this->urlAddKey("/blacklist") . "' class='button'>clear search</a></p>";
            }
        }

        let html .= "<div class='page-toolbar'>
            <a href='" . this->urlAddKey("/blacklist/add") . "' class='round icon icon-add'>&nbsp;</a>";
        if (count) {
            let html .= "<a href='" . this->urlAddKey("/blacklist/export" . filter) . "' class='round icon icon-export' title='Export Janus blacklist'>&nbsp;</a>";
        }
        let html .= "<a href='" . this->urlAddKey("/blacklist/import") . "' class='round icon icon-import' title='Import Janus blacklist'>&nbsp;</a>
        </div>";
        return html;
    }

    public function whitelist(string path)
    {
        var data, status;
        let data = this->db->get(
            "SELECT * FROM blacklist WHERE id=:id",
            [
                "id": this->cleanUrl(path, "/blacklist/white/")
            ]
        );

        if (empty(data)) {
            throw new Exception("Entry not found");
        }

        let status = this->db->execute("DELETE FROM blacklist WHERE id=:id", ["id": data->id]);
        if (!is_bool(status)) {
            throw new Exception(status);
        } 
        
        let status = this->db->get("SELECT id FROM whitelist WHERE ip=:ip", ["ip": data->ip]);
        if (!empty(status)) {
            return;
        }

        let status = this->db->execute(
            "INSERT INTO whitelist
                ('ip', 'country', 'whois', 'service', 'created_at') 
            VALUES 
                (
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
                "whois": data->whois
            ]
        );
        if (!is_bool(status)) {
            throw new Exception(status);
        }

        this->redirect(this->urlAddKey("/blacklist?whitelist=true"));
    }
}