require "yaml"
require_relative "./GlobalSettings"


global = GlobalSettings.new
global.getTemplate(Hash.new)

#settings = YAML.load_file("../globals.yaml")

#puts "Settings loaded : #{settings['LoadDBConnection1']}"
