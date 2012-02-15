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
