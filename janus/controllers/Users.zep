/**
 * Janus users
 *
 * @package     Janus\Controllers\Users
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

class Users extends Controller
{
    public routes = [
        "/users/add": "add",
        "/users/delete/": "delete",
        "/users/edit/": "edit",
        "/users": "index"
    ];

    public function add(string path)
    {
        var html;
        let html = this->pageTitle("Add a user");

        if (isset(_POST["save"])) {
            if (!this->validate(_POST, ["name", "password", "password_check"])) {
                let html .= this->error();
            } elseif (_POST["password"] != _POST["password_check"]) {
                let html .= this->error("Passwords do not match");
            } else {
                var status, data;

                let data = this->db->get("SELECT * FROM users WHERE name=:name", ["name": _POST["name"]]);
                if (data) {
                    throw new Exception("User already present");
                }

                let status = this->db->execute(
                    "INSERT INTO users ('name', 'password') VALUES (:name, :password)",
                    [
                        "name": _POST["name"],
                        "password": password_hash(_POST["password"], PASSWORD_DEFAULT)
                    ]
                );

                if (!is_bool(status)) {
                    throw new Exception(status);
                }
                let html .= this->info("Entry created");
            }
        }

        let html .= "
        <form method='POST'>
            <table class='table wfull'>
                <tbody>
                    <tr>
                        <th>Username<span class='required'>*</span></th>
                        <td>
                            <input name='name' type='text' value='" . (isset(_POST["name"]) ? _POST["name"] : "") . "'>
                        </td>
                    </tr>
                    <tr>
                        <th>Password<span class='required'>*</span></th>
                        <td>
                            <input name='password' type='password' value=''>
                        </td>
                    </tr>
                    <tr>
                        <th>Re-enter password<span class='required'>*</span></th>
                        <td>
                            <input name='password_check' type='password' value=''>
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
            <a href='/users' class='round icon icon-back' title='Back to list'>&nbsp;</a>
        </div>";

        return html;
    }

    public function delete(string path)
    {
        var data, status;
        let data = this->db->get(
            "SELECT * FROM users WHERE id=:id",
            [
                "id": this->cleanUrl(path, "/users/delete/")
            ]
        );

        if (empty(data)) {
            throw new Exception("Entry not found");
        }

        let status = this->db->execute("DELETE FROM users WHERE id=:id", ["id": data->id]);
        if (!is_bool(status)) {
            throw new Exception(status);
        } 
        this->redirect(this->urlAddKey("/users?deleted=true"));
    }

    public function edit(string path)
    {
        var html, data;
        let html = this->pageTitle("Edit the user");

        let data = this->db->get(
            "SELECT * FROM users WHERE id=:id",
            [
                "id": this->cleanUrl(path, "/users/edit/")
            ]
        );

        if (empty(data)) {
            throw new Exception("Entry not found");
        }

        if (isset(_POST["save"])) {
            if (!this->validate(_POST, ["name"])) {
                let html .= this->error();
            } else {
                var query, error = false, set = [], status;
                let query = "UPDATE users SET name=:name";

                let set = [
                    "id": data->id,
                    "name": _POST["name"]
                ];

                if (isset(_POST["password"]) && isset(_POST["password_check"])) {
                    if (_POST["password"] != _POST["password_check"]) {
                        let html .= this->error("Passwords do not match");
                        let error = true;
                    }

                    let query .= ", password=:password";
                    let set["password"] = password_hash(_POST["password"], PASSWORD_DEFAULT);
                }

                if (!error) {
                    let query .= " WHERE id=:id";

                    let status = this->db->execute(
                        query,
                        set
                    );

                    if (!is_bool(status)) {
                        throw new Exception(status);
                    }
                    let html .= this->info("Entry updated");
                }
            }
        }

        let html .= "
        <form method='POST'>
            <table class='table wfull'>
                <tbody>
                    <tr>
                        <th>Username<span class='required'>*</span></th>
                        <td>
                            <input name='name' type='text' value='" . (isset(_POST["name"]) ? _POST["name"] : data->name) . "'>
                        </td>
                    </tr>
                    <tr>
                        <th>Password<span class='required'>*</span></th>
                        <td>
                            <input name='password' type='password' value=''>
                        </td>
                    </tr>
                    <tr>
                        <th>Re-enter password<span class='required'>*</span></th>
                        <td>
                            <input name='password_check' type='password' value=''>
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
            <a href='" . this->urlAddKey("/users") . "' class='round icon icon-back' title='Back to list'>&nbsp;</a>
            <a href='" . this->urlAddKey("/users/delete/" . data->id) . "' class='round icon icon-delete' title='Delete the entry'>&nbsp;</a>
        </div>";

        return html;
    }

    public function index(string path)
    {
        var html, data;
        let html = this->pageTitle("Users");

        if (isset(_GET["deleted"])) {
            let html .= this->info("Entry deleted");
        }
        
        let data = this->db->all("SELECT * FROM users");
        if (count(data)) {
            let html .= "<table class='table wfull'>
                <thead>
                    <tr>
                        <th>User</th>
                        <th class='buttons' width='140px'>
                            <a href='" . this->urlAddKey("/users/add") . "' class='mini icon icon-add' title='Create an entry'>&nbsp;</a>
                        </th>
                    </tr>
                </thead>
                <tbody>";
            var item;
            for item in data {
                let html .= "<tr>
                    <td>" . item->name . "</td>
                    <td class='buttons'>
                        <a href='" . this->urlAddKey("/users/edit/" . item->id) . "' class='mini icon icon-edit' title='Edit the entry'>&nbsp;</a>
                        <a href='" . this->urlAddKey("/users/delete/" . item->id) . "' class='mini icon icon-delete' title='Delete the entry'>&nbsp;</a>
                    </td>
                </tr>";
            }
            let html .= "</tbody></table>";
        } else {
            let html .= "
                <h2><span>Nothing blacklisted yet</span></h2>
                <p><a href='" . this->urlAddKey("/users/add") . "' class='round icon icon-add'>&nbsp;</a></p>";
        }
        return html;
    }
}