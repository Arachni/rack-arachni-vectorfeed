=begin
    Copyright 2010-2012 Tasos Laskos <tasos.laskos@gmail.com>

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

        http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
=end

require 'rubygems'
require 'sinatra'
require 'sinatra/contrib'

require_relative '../lib/rack/arachni-vectorfeed'

def cwd
    File.expand_path( File.dirname( __FILE__ ) ) + '/'
end

VECTORS_FILE = 'vectors.yml'

use Rack::ArachniVectorFeed, outfile: cwd + VECTORS_FILE

helpers do

    def show( str )
    <<-HTML
<style type='text/css'>
    body {
        font-family: MetaBold, Trebuchet MS;
        color: #333;
    }
</style>

<body>

    <div id='toc'>
        <h2>Menu</h2>
        <ul>
            <li><a href='/'>Home</a></li>
            <li><a href='/link'>Link</a></li>
            <li>Form
                <ul>
                    <li><a href='/form/post'>POST</a></li>
                    <li><a href='/form/get'>GET</a></li>
                </ul>
            </li>
            <li><a href='/vectors'>Vectors extracted so far</a></li>
            <li><a href='/audit'>Feed the vectors to Arachni</a></li>
        </ul>
    </div>

    #{str}
</body>
HTML
    end

end

get "/" do
    cookies[:cookie_input] ||= 'cookie_blah'
    show <<-TXT
    <h2>Welcome</h2>
    Browse around for a bit and at the end check the
    <em><a href='file:///#{cwd}#{VECTORS_FILE}'>#{VECTORS_FILE}</a></em> file or
    see the <a href='/vectors'>extracted vectors</a> on-line.
    TXT
end

get "/link" do
    html = <<EOHTML
    <h2>Click the link</h2>
    <a href='?link_input=link_val'>Hello!</a>
EOHTML

    if !params.empty?
        html += <<-EOHTML
        <h3>This is what was sent:</h3>
        #{params}
        EOHTML
    end

    show html
end

get "/form/post" do
    show <<EOHTML
    <h2>Post the POST form</h2>
    <form method='post' action='?in_form_post_action=ha!'>
        <input name='form_input_post' />
        <input type='submit' />
    </form>
EOHTML
end

post '/form/post' do
    show  <<-EOHTML
    <h2>This is what was posted</h2>
    #{params}
    EOHTML
end

get "/form/get" do
    html = <<EOHTML
    <h2>Post the GET form</h2>
    <form method='get' action='?in_form_get_action=ho!'>
        <input name='form_input_get' />
        <input type='submit' />
    </form>
EOHTML

    if !params.empty?
        html += <<-EOHTML
        <h3>This is what was posted:</h3>
        #{params}
        EOHTML
    end

    show html
end

get "/vectors" do
    show <<EOHTML
    <h2>What's been extracted thus far</h2>
    <pre>#{IO.read( cwd + VECTORS_FILE )}</pre>
EOHTML
end

get "/audit" do
    url = env['rack.url_scheme'] + '://' + env['HTTP_HOST']
    show <<EOHTML
    <h2>Feed the vectors to Arachni</h2>
    <pre>arachni #{url} --plugin=vector_feed:yaml_file='#{cwd + VECTORS_FILE}' -m xss --link-count=0 --http-req-limit=1</pre>

    <h3>Why?</h3>
    <p>
        <ol>
            <li>We only use the XSS module because this is a demo. Under real world scenarios use: <pre>audit/*,grep/*</pre></li>
            <li>We set the <em>link-count</em> limit to <em>0</em> to prevent Arachni
                from crawling and only audit the stuff passed to it by the VectorFeed plug-in.</li>
            <li>We set the <em>http-req-limit</em> to <em>1</em> to throttle Arachni down since you'll
                probably been scanning <em>localost</em>.</li>
        </ol>
    </p>
EOHTML
end
