`acts_as_git_versioned`
=====================

`acts_as_git_versioned` is a proof-of-concept Rails plugin implementing versioning
of ActiveRecords using Git.

Features:

* Saving of ActiveRecord model instances as YAML files into a Git repository
* Committing changes to the Git repository

## Requirements

* Ruby on Rails (tested with 2.3.2, but should work with any 2.x)
* Grit (Currently [my own fork][1] is needed)


## Example

The following example will show the basic usage of `acts_as_git_versioned`.

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

After that you will have to commits in your Git repository `MyGit.git` with the
diff between commit #1 and commit #2 being the corrected typo in the first
`MyModel` instance.

## Credits

* Sebastian Staudt -- koraktor(at)gmail.com

## License

This code is free software; you can redistribute it and/or modify it under the
terms of the new BSD License. A copy of this license can be found in the LICENSE
file.

[1]: http://github.com/koraktor/grit

---

Copyright (c) 2009 Sebastian Staudt, released under the new BSD license
