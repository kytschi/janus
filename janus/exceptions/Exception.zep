/**
 * Generic exception
 *
 * @package     Janus\Exceptions\Exception
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
namespace Janus\Exceptions;

use Janus\Ui\Head;

class Exception extends \Exception
{
    public code;
    
	public function __construct(string message, int code = 500)
	{
        //Trigger the parent construct.
        parent::__construct(message, code);

        let this->code = code;
    }

    /**
     * Override the default string to we can have our grumpy cat.
     */
    public function __toString()
    {
        var head;
        let head = new Head();

        if (headers_sent()) {
            return "<p><strong>JANUS ERROR</strong><br/>" . this->getMessage() . "</p>";
        }

        if (this->code == 404) {
            header("HTTP/1.1 404 Not Found");
        } elseif (this->code == 400) {
            header("HTTP/1.1 400 Bad Request");
        } else {
            header("HTTP/1.1 500 Internal Server Error");
        }

        return "
        <!DOCTYPE html>
        <html lang='en'>" . head->build() . "
            <body>
                <main>
                    <div id='error' class='box'>
                        <div class='box-title'>
                            <span>Error</span>
                        </div>
                        <div class='box-body'>
                            <p>" . this->getMessage() . "</p>
                        </div>
                        <div class='box-footer'>
                            <a href='/dashboard' class='button'>back to dashboard</a>
                        </div>
                    </div>
                </main>
            </body>
        </html>";
    }

    /**
     * Fatal error just lets us dumb the error out faster and kill the site
     * so we can't go any futher.
     */
    public function fatal(string template = "", int line = 0)
    {
        echo this;
        if (template && line) {
            echo "<p>&nbsp;&nbsp;<strong>Trace</strong><br/>&nbsp;&nbsp;Source <strong>" . str_replace(getcwd(), "", template) . "</strong> at line <strong>" . line . "</strong></p>";
        }
        die();
    }
}
