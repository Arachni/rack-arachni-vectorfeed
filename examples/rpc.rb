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
require 'arachni/rpc/pure'

# serialized vectors as dumped by the ArachniVectorFeed midleware
VECTOR_FILE = File.expand_path( File.dirname( __FILE__ ) ) + '/vectors.yml'

# dispatcher options
DISPATCHER = {
    host: 'localhost',
    port: 7331
}

raise VECTOR_FILE + ' does not exist.' if !File.exist?( VECTOR_FILE )

YAML_VECTORS = IO.read( VECTOR_FILE )

# connect to the dispatcher
dispatcher = Arachni::RPC::Pure::Client.new( DISPATCHER )

# request an arachni instance
instance_info = dispatcher.call( 'dispatcher.dispatch' )

host, port = instance_info['url'].split( ':' )
# connect to the instance
instance = Arachni::RPC::Pure::Client.new(
    host: host,
    port: port,
    token: instance_info['token']
)

begin
    opts = {
        # it'll be used as a general frame of reference by the framework.
        'url'           => YAML.load( YAML_VECTORS ).first['action'],

        # audit pretty much every available vector type
        'audit_links'   => true,
        'audit_forms'   => true,
        'audit_cookies' => true,
        'audit_headers' => true,

        # don't crawl! just audit the vectors
        'link_count_limit' => 0,

        # throttle arachni down for this test, no concurrency
        'http_req_limit' => 1
    }

    # this is a demo so just load the XSS module
    instance.call( 'modules.load', [ 'xss' ] )

    plugins = {
        # feed the vectors to the plugin
        'vector_feed' => {
            'yaml_string' => YAML_VECTORS
        }
    }

    instance.call( 'plugins.load', plugins )

    # set the options
    instance.call( 'opts.set', opts )

    # start the show!
    instance.call( 'framework.run' )

    #
    # wait until the framework finishes
    #
    # you can also request a report at any point during the scan to get results
    # as they are logged but let's keep it simple for the example
    #
    print "Running"
    while( instance.call( 'framework.busy?' ) )
        sleep( 1 )
        print '.'
    end
    puts 'Done!'

rescue
    puts
    puts 'Something bad happened.'
    instance.call( "framework.clean_up!" )
ensure

    puts "Report:"
    puts '--------------'
    # YAML looks pretty :)
    puts instance.call( 'framework.report' )['issues'].to_yaml

    puts "[Shutting down]"
    instance.call( 'service.shutdown' )
end
