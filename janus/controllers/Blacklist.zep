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
        "/blacklist": "index"
    ];

    public function add(string path)
    {
        var html, status, ip="";
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

                let status = this->db->execute(
                    "INSERT OR REPLACE INTO blacklist
                        (id, 'ip', 'country', 'service', 'whois', 'created_at') 
                    VALUES 
                        (
                            (SELECT id FROM blacklist WHERE ip=:ip),
                            :ip,
                            :country,
                            :service,
                            :whois,
                            :created_at
                        )",
                    [
                        "ip": _POST["ip"],
                        "country": country,
                        "service": service,
                        "whois": whois,
                        "created_at": date("Y-m-d")
                    ]
                );

                if (!is_bool(status)) {
                    throw new Exception(status);
                }
                unset(_POST["ip"]);
                let html .= this->info("Entry created");
            }
        }

        let html .= "
        <form method='POST'>
            <table class='table wfull'>
                <tbody>
                    <tr>
                        <th>IP</th>
                        <td>
                            <input name='ip' type='text' value='" . (ip ? ip : "") . "'>
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
        var html, data;
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

        let html .= "
        <table class='table wfull'>
            <tbody>
                <tr>
                    <th>IP</th>
                    <td>" . data->ip . "</td>
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
                <tr>
                    <th colspan='2'>Whois</th>
                </tr>
                <tr>
                    <td colspan='2' class='log-output'>" . data->whois . "</td>
                </tr>
            </tbody>
        </table>
        <div class='page-toolbar'>
            <a href='" . this->urlAddKey("/blacklist") . "' class='round icon icon-back' title='Back to list'>&nbsp;</a>
            <a href='" . this->urlAddKey("/blacklist/delete/" . data->id) . "' class='round icon icon-delete' title='Delete the entry'>&nbsp;</a>
            <a href='" . this->urlAddKey("/blacklist/white/". data->id) . "' class='round icon icon-whitelist align-right' title='Whitelist the entry'>&nbsp;</a>
        </div>
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

    public function index(string path)
    {
        var html, data, query, vars=[];
        let html = this->pageTitle("Blacklisted IPs");

        if (isset(_GET["deleted"])) {
            let html .= this->info("Entry deleted and will be removed from blacklist");
        } elseif (isset(_GET["whitelist"])) {
            let html .= this->info("Entry has been marked for whitelisting");
        }
        
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
            let query .= " WHERE blacklist.ip LIKE :query";
            let vars["query"] = "%" . _POST["q"] . "%";
        }
        let query .= " ORDER BY patterns DESC, blacklist.ip ASC";

        let data = this->db->all(query, vars);
        if (count(data)) {
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
                        <th>Country</th>
                        <th>Service</th>
                        <th>Whitelisted</th>
                        <th class='buttons' width='140px'>
                            <a href='" . this->urlAddKey("/blacklist/add") . "' class='mini icon icon-add' title='Create an entry'>&nbsp;</a>
                        </th>
                    </tr>
                </thead>
                <tbody>";
            var item;
            for item in data {
                let html .= "<tr>
                    <td>" . item->ip . "</td>
                    <td>" . item->patterns . "</td>
                    <td>" . item->country . "</td>
                    <td>" . item->service . "</td>
                    <td>" . (item->whitelisted ? "<span class='tag'>YES</span>" : "NO") . "</td>
                    <td class='buttons'>
                        <a href='" . this->urlAddKey("/blacklist/edit/" . item->id) . "' class='mini icon icon-edit' title='Edit the entry'>&nbsp;</a>
                        <a href='" . this->urlAddKey("/blacklist/white/" . item->id) . "' class='mini icon icon-whitelist' title='Whitelist the entry'>&nbsp;</a>
                        <a href='" . this->urlAddKey("/blacklist/delete/" . item->id) . "' class='mini icon icon-delete' title='Delete the entry'>&nbsp;</a>
                    </td>
                </tr>";
            }
            let html .= "</tbody></table>";
        } else {
            let html .= "<h2><span>Nothing found</span></h2>";
            if (isset(_POST["q"])) {
                let html .= "<p><a href='" . this->urlAddKey("/blacklist") . "' class='button'>clear search</a></p>";
            }
            let html .= "<p><a href='" . this->urlAddKey("/blacklist/add") . "' class='round icon icon-add'>&nbsp;</a></p>";
        }
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
        
        let status = this->db->execute(
            "INSERT OR REPLACE INTO whitelist
                (id, 'ip', 'country', 'whois', 'service', 'created_at') 
            VALUES 
                (
                    (SELECT id FROM whitelist WHERE ip=:ip),
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