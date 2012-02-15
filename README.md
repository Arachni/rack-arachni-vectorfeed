# Rack::ArachniVectorFeed middleware

Extracts input (link, form, cookie, header) vectors/params from HTTP requests
and exports them in a suitable format for use with [Arachni](http://arachni-scanner.com)'s VectorFeed plug-in
in order to perform extremely focused audits or unit-tests.

## Installation

### Gemfile

```ruby
gem 'rack-arachni-vectorfeed',
    :git => 'git://github.com/Arachni/rack-arachni-vectorfeed.git',
    :require => 'rack/arachni-vectorfeed'
```

### Rails 3

Once you have followed the instructions for Gemfile installation you can then
choose an environment and add the following to its configuration:

```ruby
config.middleware.use Rack::ArachniVectorFeed, outfile: 'vectors.yml'
```

### Source

```
git clone git://github.com/Arachni/rack-arachni-vectorfeed.git
cd rack-arachni-vectorfeed
rake install
```

## Usage

The main idea behind this is to lead to security Unit-testing using [Arachni](http://arachni-scanner.com) and its VectorFeed plug-in.

For example, you can configure your Rails test environment to use this midleware
and then run your tests as usual.<br/>
This time though, once the tests finish you'll be left with a YAML file containing
all the HTTP inputs that were used in those tests.

You can then pass that file to Arachni's VectorFeed plug-in and let it audit
these inputs all the while enjoying as wide a coverage as your tests -- which will also enable
you to skip the crawl by setting the <em>link-count</em> limit to <em>0</em>.

Like so:

```
arachni <url> --plugin=vector_feed:yaml_file='<vectors file>' -m audit/* --link-count=0
```

This will load all audit modules and attack the extracted vectors while skipping the crawl.

If you want to automate the process you can:

* start-up an [Arachni Dispatcher](http://arachni-scanner.com/wiki/RPC-server)
* run the tests
* once they finish use the RPC interface to automate the scan (see <em>examples/rpc.rb</em>)
* integrate the results of the audit back to the test suite

As you can seem this is still a very young project and still quite abstract.

**Note**: Of course, you can use the VectorFeed plug-in to extend the audit
instead of restricting it -- that depends on what you want.


## Example

Run the script <em>examples/server.rb</em> to see this working live.

### Quickie

You can use it in any Rack-based app like so:

```ruby
require 'rubygems'
require 'sinatra'
require 'sinatra/contrib'

require 'rack/arachni-vectorfeed'

use Rack::ArachniVectorFeed, outfile: 'vectors.yml'

get "/" do
    cookies[:cookie_input] ||= 'cookie_blah'
    'hello'
end

get "/example" do
    <<EOHTML
    <form method='post' action='?get_input=ha!'>
        <input name='test' />
        <input type='submit' />
    </form>
EOHTML
end

post '/example' do
    p params
end

```
