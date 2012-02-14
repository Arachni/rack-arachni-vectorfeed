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

Gem::Specification.new do |s|
    s.name     = "rack-arachni-vectorfeed"
    s.version  = "0.1"
    s.platform = Gem::Platform::RUBY
    s.authors  = [ "Tasos Laskos" ]
    s.email    = [ "tasos.laskos@gmail.com" ]
    s.homepage = "https://github.com/Arachni/rack-arachni-vectorfeed"
    s.summary  = %q{Rack midleware which extracts vectors from HTTP requests for use with Arachni's VectorFeed plug-in.}
    s.description = %q{}

    s.add_runtime_dependency 'rack', '>= 1.0.0'

    s.files = `git ls-files`.split( "\n" )
    s.require_paths = ["lib"]
end
