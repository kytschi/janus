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

use Janus\Exceptions\Exception;
use Janus\Ui\Head;

class Controller
{
    public db;
    public routes = [];
    public settings;

    public function cleanUrl(string path, string clean)
    {
        return str_replace(
            "/" . (this->settings ? this->settings->url_key : "") . clean,
            "",
            path
        );
    }

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
            let output = trim(implode(",", splits));
            return (output) ? output : "UNKNOWN";
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
        let head = new Head(this->settings);

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

        let this->db = database;
        let this->settings = settings;

        for route, func in this->routes {
            if (strpos(path, this->urlAddKey(route)) !== false) {
                return this->{func}(path);
            }
        }

        return "";
    }

    public function urlAddKey(string path)
    {
        return "/" . (this->settings ? this->settings->url_key : "") . path;
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

    public function writeCronFiles(bool write_files = false)
    {
        if (write_files) {
            var data, item, file;

            // Write the blacklist IPs for CRON.
            let data = this->db->all("SELECT * FROM blacklist");
            let file = fopen(rtrim(this->settings->cron_folder, "/") . "/blacklist", "w");
            if (!file) {
                throw new Exception("Failed to write blacklist file for CRON");
            }
            for item in data {
                fwrite(file, item->ip. "\n");
            }
            fclose(file);

            // Write the whitelist IPs for CRON.
            let data = this->db->all("SELECT * FROM whitelist");
            let file = fopen(rtrim(this->settings->cron_folder, "/") . "/whitelist", "w");
            if (!file) {
                throw new Exception("Failed to write whitelist file for CRON");
            }
            for item in data {
                fwrite(file, item->ip . "\n");
            }
            fclose(file);
            return;
        }
        
        var err;

        try {
            // Write the cron.
            file_put_contents(
                rtrim(this->settings->cron_folder, "/") . "/cron.sh",
                "#!/bin/bash
# DO NOT EDIT, AUTOMATICALLY CREATED BY JANUS

php -r \"use Janus\\Janus; new Janus('" . this->settings->db_file . "', '', true);\";

DIR=$(dirname -- \"$0\";)
IPTABLES=" . this->settings->firewall_command . "
IP_BLACKLIST=$DIR/blacklist
IP_WHITELIST=$DIR/whitelist
CONF=" . this->settings->firewall_cfg_folder . this->settings->firewall_cfg_file_v4 . "
            
# Create the chain JANUS_BLACKLIST
$IPTABLES -N JANUS_BLACKLIST
            
# Empty the chain JANUS_BLACKLIST before adding rules
$IPTABLES -F JANUS_BLACKLIST
            
# Read $IP_BLACKLIST and add IP into IPTables one by one
/bin/egrep -v \"^#|^$|:\" $IP_BLACKLIST | sort | uniq | while read IP
do
    $IPTABLES -A JANUS_BLACKLIST -s $IP -j DROP
done

# Create the chain JANUS_WHITELIST
$IPTABLES -N JANUS_WHITELIST
            
# Empty the chain JANUS_WHITELIST before adding rules
$IPTABLES -F JANUS_WHITELIST
            
# Read $IP_WHITELIST and add IP into IPTables one by one
/bin/egrep -v \"^#|^$|:\" $IP_WHITELIST | sort | uniq | while read IP
do
    $IPTABLES -A JANUS_WHITELIST -s $IP -j DROP
done
            
# Save current configuration to file
if [ ! -d \"" . this->settings->firewall_cfg_folder . "\" ]
then
    mkdir " . this->settings->firewall_cfg_folder . "
fi
$IPTABLES-save > $CONF"
        );
        } catch \Exception, err {
            throw new Exception("Failed to write the cron.sh, " . err->getMessage());
        }
    }
}