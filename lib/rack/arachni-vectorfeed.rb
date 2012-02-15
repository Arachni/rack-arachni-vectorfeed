require 'rack/utils'
require 'yaml'
# require 'ap'

module Rack
    class ArachniVectorFeed
        include Rack::Utils

        def initialize( app, opts )
            @app  = app
            @opts = opts

            raise "Option 'outfile' is mandatory." if !opts[:outfile]

            @vectors = Set.new
        end

        def call( env )
            # ap env

            extract_vectors( env ).each {
                |vector|
                if !@vectors.include? vector
                    @vectors << vector
                    append_to_outfile( vector )
                end
            }

            # forward the request up to the app
            @app.call( env )
        end

        private

        def append_to_outfile( vector )
            ::File.open( @opts[:outfile], 'a' ) do |out|
                YAML.dump( [vector], out )
            end
        end

        def extract_vectors( env )
            [extract_cookies( env ), extract_headers( env ),
            extract_forms( env ), extract_links( env ) ].flatten.compact
        end

        def extract_links( env )
            return if !env['QUERY_STRING']

            input_arr = env['QUERY_STRING'].split( '&' ).map {
                |pair|
                k, v = pair.split( '=', 2 )
                { k => v }
            }

            inputs = {}
            input_arr.each {
                |input|
                inputs.merge!( input )
            }

            if !inputs.empty?
                vector_tpl( env ).merge(
                    'type' => 'link',
                    'method' => 'get',
                    'inputs' => inputs
                )
            end
        end

        def extract_forms( env )
            return if !env['rack.request.form_hash']

            vector_tpl( env ).merge(
                'type' => 'form',
                'inputs' => env['rack.request.form_hash']
            )
        end

        def extract_cookies( env )
            return if !env['HTTP_COOKIE'] || env['HTTP_COOKIE'].empty?

            env['HTTP_COOKIE'].split( '; ' ).map {
                |pair|
                k, v = pair.split( '=', 2 )
                { k => v }
            }.map {
                |cookie|
                vector_tpl( env ).merge(
                    'method' => 'get',
                    'type'   => 'cookie',
                    'inputs' => cookie
                )
            }
        end

        def extract_headers( env )
            # this handles request headers
            headers = {}
            env.select { |k,v| k.start_with? 'HTTP_' }
                .collect { |pair| [pair[0].sub( /^HTTP_/, ''), pair[1] ] }
                .sort.map {
                    |k, v|
                    canon = k.gsub( '_', '-' ).capitalize
                    vector_tpl( env ).merge(
                        'method' => 'get',
                        'type'   => 'header',
                        'inputs' => { canon => v }
                    )
                }
        end

        def vector_tpl( env )
            vector = {
                'method' => env['REQUEST_METHOD'].downcase,
                'action' => env['rack.url_scheme'] + '//' + env['HTTP_HOST'] +
                    env['REQUEST_URI']
            }
        end

    end
end
