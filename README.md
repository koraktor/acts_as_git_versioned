= acts_as_git_versioned

acts_as_git_versioned is a proof-of-concept Rails plugin implementing versioning
of ActiveRecords using Git.

Features:
* Saving of ActiveRecord model instances as YAML files into a Git repository
* Committing changes to the Git repository


== Example

The following example will show the basic usage of acts_as_git_versioned.

  class MyModel < ActiveRecord::Base
    acts_as_git_versioned({:repository => 'MyGit.git'})

    attr_accessible :name
  end

...

  # Creating two instances of MyModel
  MyModel.create(:name => "First MyMdel instance")
  MyModel.create(:name => "Second MyModel instance")
  MyModel.commit

  # Correcting typo for the first instance
  MyModel.first.update_attribute(:name => "First MyModel instance")
  MyModel.commit

After that you will have to commits in your Git repository MyGit.git with the
diff between commit #1 and commit #2 being the corrected typo in the first
+MyModel+ instance.

---

Copyright (c) 2009 Sebastian Staudt, released under the new BSD license
