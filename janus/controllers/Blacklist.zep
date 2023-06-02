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
        "/blacklist/delete/": "delete",
        "/blacklist/edit/": "edit",
        "/blacklist/white/": "whitelist",
        "/blacklist": "index"
    ];

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
            "SELECT * FROM found_block_patterns WHERE ip=:ip GROUP BY pattern ORDER BY label",
            [
                "ip": data->ip
            ]
        );
        if (count(data)) {
            let html .= "<table class='table wfull'>
                <thead>
                    <tr>
                        <th>Pattern</th>
                        <th width='200px'>Label</th>
                        <th width='200px'>Category</th>
                    </tr>
                </thead>
                <tbody>";
            var item;
            for item in data {
                let html .= "<tr>
                    <td>" . item->pattern . "</td>
                    <td>" . item->label . "</td>
                    <td>" . item->category . "</td>
                </tr>";
            }
            let html .= "</tbody></table>";
        } else {
            let html .= "
                <h2><span>No patterns yet</span></h2>
                <p><a href='" . this->urlAddKey("/patterns/add") . "' class='round icon icon-add'>&nbsp;</a></p>";
        }

        return html;
    }

    public function index(string path)
    {
        var html, data;
        let html = this->pageTitle("Blacklisted IPs");

        if (isset(_GET["deleted"])) {
            let html .= this->info("Entry deleted and will be removed from blacklist");
        } elseif (isset(_GET["whitelist"])) {
            let html .= this->info("Entry has been marked for whitelisting");
        }
        
        let data = this->db->all("SELECT * FROM blacklist");
        if (count(data)) {
            let html .= "<table class='table wfull'>
                <thead>
                    <tr>
                        <th width='200px'>IP</th>
                        <th>Country</th>
                        <th>Service</th>
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
                    <td>" . item->country . "</td>
                    <td>" . item->service . "</td>
                    <td class='buttons'>
                        <a href='" . this->urlAddKey("/blacklist/edit/" . item->id) . "' class='mini icon icon-edit' title='Edit the entry'>&nbsp;</a>
                        <a href='" . this->urlAddKey("/blacklist/white/" . item->id) . "' class='mini icon icon-whitelist' title='Whitelist the entry'>&nbsp;</a>
                        <a href='" . this->urlAddKey("/blacklist/delete/" . item->id) . "' class='mini icon icon-delete' title='Delete the entry'>&nbsp;</a>
                    </td>
                </tr>";
            }
            let html .= "</tbody></table>";
        } else {
            let html .= "
                <h2><span>Nothing blacklisted yet</span></h2>
                <p><a href='" . this->urlAddKey("/blacklist/add") . "' class='round icon icon-add'>&nbsp;</a></p>";
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
                (id, 'ip', 'country', 'whois', 'service') 
            VALUES 
                (
                    (SELECT id FROM whitelist WHERE ip=:ip),
                    :ip,
                    :country,
                    :whois,
                    :service
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