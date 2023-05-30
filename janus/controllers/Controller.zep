/**
 * Janus controller
 *
 * @package     Janus\Controllers\Controller
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

use Janus\Ui\Head;

class Controller
{
    public db;
    public routes = [];

    public function createInputText(
            string label,
            string var_name,
            string placeholder,
            bool required = false,
            value = null
    ) {
        if (empty(value)) {
            let value = (isset(_POST[var_name]) ? _POST[var_name] : "");
        }

        return "<div class='input-group'>
            <span>" . label . (required ? "<span class='required'>*</span>" : "") . "</span>
            <input
                type='text'
                name='" . var_name . "' 
                placeholder='' " . 
                "value=\"" . value . "\"'>
        </div>";
    }

    public function pageTitle(string title)
    {
        var head;
        let head = new Head();

        return "<h1>" . title . "</h1>" . head->toolbar();
    }

    public function router(string path, database)
    {
        var route, func;

        for route, func in this->routes {
            if (strpos(path, route) !== false) {
                let this->db = database;
                return this->{func}(path);
            }
        }

        return "";
    }
}