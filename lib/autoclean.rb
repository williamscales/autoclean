require 'yaml'
require 'date'
require 'rubygems'
require 'chronic'
require 'fileutils'

module Autoclean
  VERSION = 0.1

  # Load the rules file, perform any necessary parsing.  For now all
  # we have to do is use YAML to load the file.
  def self.parse_rules_file(rules_file)
    rules = YAML.load_file(rules_file)
  end

  # Provided a set of rules, do the cleaning.
  def self.clean(rules)
    for rule in rules
      files = Dir.glob(rule[:glob])
      
      # If there is an 'unless' condition, remove the files that meet
      # that condition from 'files'
      unless rule[:unless].nil?
        case rule[:unless][0]
          
          # FIXME: this is just a stub
        when 'match'
          regex = Regexp.new(rule[:unless][1])
          
          # Compare the basename of the 'file' to the basename of other
          # files from a glob, if it matches any of them it will be
          # removed from 'files'
        when 'like'
          # Make a hash of our files indexed by the basename
          basenames = {}
          files.each {|f| basenames[File.basename(f).split('.')[0]] = f}
            
          like_files = Dir.glob(rule[:unless][1])
          like_files.map! {|f| File.basename(f).split('.')[0]}
          
          for like_file in like_files
            if basenames.has_key?(like_file)
              files.delete(basenames[like_file])
            end
          end
          
        end
      end

      # If we have some condition, remove the files that do not meet
      # that condition from 'files'

      unless rule[:condition].nil?
        case rule[:condition][0]
        when 'age'
          # Parse the condition string
          operator = rule[:condition][1].slice!(0).chr
          date = Chronic.parse(rule[:condition][1])

          for file in files
            mtime = File.mtime(file)
            
            case operator
            when '>'
              if (mtime <=> date) == 1
                files.delete(file)
              end
            when '<'
              if (mtime <=> date) == (-1 || 0)
                files.delete(file)
              end
            end
            
          end
          
        end
      end
      
      # We now have our list of actionable files, now let's clean!

      if rule[:action].is_a?(String)
        case rule[:action]
        when 'delete'
          files.each {|f| FileUtils::Verbose.rm_rf(f) }
        end
      elsif rule[:action].is_a?(Array)
        case rule[:action][0]
        when 'move'
          destination = rule[:action][1]
          files.each {|f| FileUtils::Verbose.mv(f, destination) }
        end
      end

    end
  end
end
