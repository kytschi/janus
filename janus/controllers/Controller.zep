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
    public settings;

    public function error(string message = "Missing required fields")
    {
        return "<div class='error box wfull'>
        <div class='box-title'>
            <span>Error</span>
        </div>
        <div class='box-body'>
            <p>" . message . "</p>
        </div></div>";
    }

    public function getCountry(ip)
    {
        var output, splits;
        let output = shell_exec("geoiplookup " . ip);
        if (output) {
            let splits = explode(":", output);
            let splits = explode(",", splits[count(splits) - 1]);
            unset(splits[0]);
            return trim(implode(",", splits));
        }
        return "UNKNOWN";
    }

    public function getService(ip)
    {
        var output, line, lines, netname = null;

        let output = shell_exec("whois " . ip);
        if (output) {
            let lines = explode("\n", strtolower(output));
            
            for line in lines {
                if(strpos(line, "orgname:") !== false) {
                    let netname = trim(ltrim(line, "orgname:"));
                    break;
                }

                if(strpos(line, "org-name:") !== false && !netname) {
                    let netname = trim(ltrim(line, "org-name:"));
                }

                if(strpos(line, "netname:") !== false) {
                    let netname = trim(ltrim(line, "netname:"));
                }

                if(strpos(line, "owner:") !== false && !netname) {
                    let netname = trim(ltrim(line, "owner:"));
                }

                if(strpos(line, "organization name") !== false && !netname) {
                    let netname = str_replace([":"], "", trim(ltrim(line, "organization name")));
                }
                

                if(strpos(line, "descr:") !== false && netname) {
                    let netname = trim(ltrim(line, "descr:"));
                    break;
                }
            }
        }
        
        return [
            output,
            (netname) ? ucwords(strtolower(netname)) : "UNKNOWN"
        ];
    }

    public function info(string message)
    {
        return "<div class='info box wfull'>
            <div class='box-title'>
                <span>Info</span>
            </div>
            <div class='box-body'>
                <p>" . message . "</p>
            </div></div>";
    }

    public function pageTitle(string title)
    {
        var head;
        let head = new Head();

        return "<h1><span>" . title . "</span></h1>" . head->toolbar();
    }

    public function redirect(string url)
    {
        header("Location: " . url);
        die();
    }

    public function router(string path, database, settings)
    {
        var route, func;

        for route, func in this->routes {
            if (strpos(path, route) !== false) {
                let this->db = database;
                let this->settings = settings;
                return this->{func}(path);
            }
        }

        return "";
    }

    public function validate(array data, array checks)
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