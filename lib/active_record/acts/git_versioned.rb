module ActiveRecord
  module Acts
    module GitVersioned

      def self.included(base) #:nodoc:
        base.extend ClassMethods
      end

      module ClassMethods

        # Extends this model to be capable of maintaining a history of its
        # instances in a Git repository.
        #
        # * +options+: A hash of configuration options as listed below:
        #
        # == Configuration options
        # * +repository+: The path the Git repository should be saved to,
        #   relative to RAILS_ROOT (default: 'acts_as_git_versioned.git')
        # * +author_name+: Sets the commit author's name (default:
        #   'acts_as_git_versioned')
        # * +author_email+: Sets the commit author's email address (default:
        #   'acts_as_git_versioned@localhost')
        # * +auto_commit+: If this is set, each save called on an instance of
        #   this model will commit to the repository (default: false). Requires
        #   +auto_save+ to be set.
        # * +auto_save+: If this is set, each save called on an instance of
        #   this model will also update the corresponding file in the working
        #   tree (default: true)
        def acts_as_git_versioned(options = {})
          return if self.included_modules.include?(ActiveRecord::Acts::GitVersioned::InstanceMethods)

          send :include, ActiveRecord::Acts::GitVersioned::InstanceMethods

          unless self.const_defined? :Grit
            require_library_or_gem 'Grit'
          end

          cattr_accessor :repository, :repository_path

          options[:auto_commit] ||= false
          options[:auto_save]   ||= true

          self.repository_path = File.join(RAILS_ROOT, (options[:repository] || 'acts_as_git_versioned.git'))
          self.repository = Grit::Repo.init repository_path
          self.repository.config['user.name']  = options[:author_name]  || 'acts_as_git_versioned'
          self.repository.config['user.email'] = options[:author_email] || 'acts_as_git_versioned@localhost'

          if options[:auto_save]
            after_save :save_to_git
            if options[:auto_commit]
              after_save :commit
            end
          end
        end

        # Commits all changes to the instances of this model to the Git
        # repository
        #
        # * +message+: Appends a message to the commit (default: none)
        # * +oneline+: Sets the oneline of the commit message. (default:
        #   'Committing changeset #i' where +i+ is the number of the current
        #   commit)
        #
        # == Example
        # +MyModel+.+commit+ will result in a commit message like:
        #  Committing changeset #18
        # +MyModel+.+commit+ 'Fixing typo in MyModel name'+ will result in a
        # commit message like:
        #  Committing changeset #18
        #
        #  Fixing typo in MyModel name
        # +MyModel+.+commit+ 'Fixing typo in MyModel name', 'Fixes changeset
        # #17' will result in a commit message like:
        #  Fixes changeset #17
        #
        #  Fixing typo in MyModel name
        def commit(message = nil, oneline = nil)
          commit_message = oneline || "Committing changeset #{repository.commits.size + 1}"
          commit_message << "\n\n" << message unless message.nil?
          self.repository.commit_all commit_message
        end

      end

      module InstanceMethods

        def self.included(base) #:nodoc:
          base.extend ClassMethods
        end

        # Adds the blob of this model to the index of the Git repository
        def add_blob
          repository.add(blob_path)
        end

        # Saves the data of the model into a file in the working tree of the Git
        # repository. If this file hasn't been already added the repository
        # (i.e. this is the first save of this object) this is done now
        def save_to_git
          FileUtils.makedirs File.dirname(blob_path(false)) unless File.exists? File.dirname(blob_path(false))
          File.open(blob_path(false), 'w') do |file|
            file.write to_yaml_git
          end
          if (repository.tree/blob_path).nil?
            add_blob
          end
        end

        # Custom version of Object#to_yaml to only capture the +attributes+
        # instance variable of ActiveRecord::Base
        def to_yaml_git(opts = {})
         YAML::quick_emit(self, opts) do |out|
            out.map(taguri, to_yaml_style) do |map|
              map.add("attributes", @attributes)
            end
          end
        end

        protected

        # Returns the path of the blob. If +relative+ is +true+ it returns the
        # relative path (as inside the repository), otherwise the abosulte path
        # in the file system
        def blob_path(relative = true)
          blob_path = File.join(self.class.name, hash.to_s)
          if relative
            blob_path
          else
            File.join(repository_path, blob_path)
          end
        end

      end
    end
  end
end
