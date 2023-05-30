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
        "/blacklist/edit/": "edit",
        "/blacklist": "index"
    ];

    public function edit(string path)
    {
        var html, data;
        let html = this->pageTitle("Blacklisted IP");

        let data = this->db->get(
            "SELECT * FROM blacklist WHERE id=:id",
            [
                "id": str_replace("/blacklist/edit/", "", path)
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

        return html;
    }

    public function index(string path)
    {
        var html, data;
        let html = this->pageTitle("Blacklisted IPs");
        
        let data = this->db->all("SELECT * FROM blacklist");
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
                        <a href='/blacklist/edit/" . item->id . "' class='mini icon icon-edit' title='Edit the entry'>&nbsp;</a>
                        <a href='/blacklist/delete/" . item->id . "' class='mini icon icon-delete' title='Delete the entry'>&nbsp;</a>
                        <a href='/blacklist/whitelist/" . item->id . "' class='mini icon icon-whitelist' title='Whitelist the entry'>&nbsp;</a>
                    </td>
                </tr>";
            }
            let html .= "</tbody></table>";
        } else {
            let html .= "<h2>Nothing blacklisted yet</h2>";
        }
        return html;
    }
}