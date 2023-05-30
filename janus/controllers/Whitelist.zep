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
        "/whitelist/delete/": "delete",
        "/whitelist/edit/": "edit",
        "/whitelist/blacklist/": "blacklist",
        "/whitelist": "index"
    ];

    public function blacklist(string path)
    {
        var data, status;
        let data = this->db->get(
            "SELECT * FROM whitelist WHERE id=:id",
            [
                "id": str_replace("/whitelist/blacklist/", "", path)
            ]
        );

        if (empty(data)) {
            throw new Exception("Entry not found");
        }

        let status = this->db->execute("DELETE FROM whitelist WHERE id=:id", ["id": data->id]);
        if (!is_bool(status)) {
            throw new Exception(status);
        } 
        
        let status = this->db->execute(
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
                "ip": data->ip,
                "country": data->country,
                "service": data->service,
                "whois": data->whois
            ]
        );
        if (!is_bool(status)) {
            throw new Exception(status);
        } 

        this->redirect("/whitelist?blacklist=true");
    }

    public function delete(string path)
    {
        var data, status;
        let data = this->db->get(
            "SELECT * FROM whitelist WHERE id=:id",
            [
                "id": str_replace("/whitelist/delete/", "", path)
            ]
        );

        if (empty(data)) {
            throw new Exception("Entry not found");
        }

        let status = this->db->execute("DELETE FROM whitelist WHERE id=:id", ["id": data->id]);
        if (!is_bool(status)) {
            throw new Exception(status);
        } 
        this->redirect("/whitelist?deleted=true");
    }

    public function edit(string path)
    {
        var html, data;
        let html = this->pageTitle("Whitelist IP");

        let data = this->db->get(
            "SELECT * FROM whitelist WHERE id=:id",
            [
                "id": str_replace("/whitelist/edit/", "", path)
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
                    <td colspan='2'><pre>" . data->whois . "</pre></td>
                </tr>
            </tbody>
        </table>";

        let html .= "<div class='page-toolbar'>
            <a href='/whitelist' class='round icon icon-back' title='Back to list'>&nbsp;</a>
            <a href='/whitelist/delete/" . data->id . "' class='round icon icon-delete' title='Delete the entry'>&nbsp;</a>
            <a href='/whitelist/blacklist/" . data->id . "' class='round icon icon-blacklist align-right' title='Blacklist the entry'>&nbsp;</a>
        </div>";

        return html;
    }

    public function index(string path)
    {
        var html, data;
        let html = this->pageTitle("Whitelist IPs");

        if (isset(_GET["deleted"])) {
            let html .= this->info("Entry deleted and will be removed from whitelist");
        } elseif (isset(_GET["blacklist"])) {
            let html .= this->info("Entry has been marked for blacklisting");
        }
        
        let data = this->db->all("SELECT * FROM whitelist");
        if (count(data)) {
            let html .= "<table class='table wfull'>
                <thead>
                    <tr>
                        <th width='200px'>IP</th>
                        <th>Country</th>
                        <th>Service</th>
                        <th width='160px'>&nbsp;</th>
                    </tr>
                </thead>
                <tbody>";
            var item;
            for item in data {
                let html .= "<tr>
                    <td>" . item->ip . "</td>
                    <td>" . item->country . "</td>
                    <td>" . item->service . "</td>
                    <td>
                        <a href='/whitelist/edit/" . item->id . "' class='mini icon icon-edit' title='Edit the entry'>&nbsp;</a>
                        <a href='/whitelist/delete/" . item->id . "' class='mini icon icon-delete' title='Delete the entry'>&nbsp;</a>
                        <a href='/whitelist/blacklist/" . item->id . "' class='mini icon icon-blacklist' title='Blacklist the entry'>&nbsp;</a>
                    </td>
                </tr>";
            }
            let html .= "</tbody></table>";
        } else {
            let html .= "<h2><span>Nothing whitelisted yet</span></h2>";
        }
        return html;
    }
}