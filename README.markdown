aux codes
=========

Getting Started
---------------

A good way to get started might be to checkout the screencasts

 - [Introducing AuxCodes](http://remi.org/2009/02/07/introducing-auxcodes.html)
 - [AuxCodes on Rails](http://remi.org/2009/02/08/auxcodes-on-rails.html)

Background
----------

Way back when, when I was learning database development, a mentor of mine showed me 
a technique that he liked to use to consolidate similar enum-esque database tables.

Often, applications have enum-esque tables that merely store simply key / value pairs, 
typically a unique ID and a string.  Take for instance, a `genders` table:

    [  genders   ]
    [id]    [name]
    1       Male
    2       Female

That's a bit of a waste of a table, *especially* if your application has *TONS* of tables 
just like this.  There's where aux codes (or auxilary codes) come in!

    [  aux_codes  ]
    [id]   [category_id]   [name]
    1      0               Genders    <--- this defines a 'table' (because category_id = 0)
    2      1               Male       <--- these are under category_id 1 (Genders)
    3      1               Female
    4      0               Colors     <--- defines a color 'table'
    5      4               Red        <--- category_id 4 = 'Colors', so this is a color
    6      4               Blue

Simple, eh?

Now, this is great, but this might get in the way of our business logic or it might 
dirty up our code.  We don't want to always be using the AuxCode object with complex 
queries ... we probable want a Gender object that behaves just like it would with a
full-blown genders table.

    Gender = AuxCode.category('Gender').aux_code_class

    # the Gender class is a full-blown ActiveRecord class
    # that should behave as if there's actually a `genders` table!

    Gender.find_by_name 'Male'

    Gender.find_or_create_by_name 'Female'

    Gender.create :name => 'Female'

    male = Gender.new :name => 'Male'
    male.save

    Gender.find :conditions => ['name = ?', 'Male']

    Gender.count

    Gender.codes
    Gender.code_names
    Gender.aux_code
    Gender.aux_codes

If you want to create all of these classes at once, as constants:

    AuxCode.create_classes!

You can also access codes with a Hash-like syntax

    AuxCode['Genders']['Male']
    AuxCode[:Genders][:Female]

    Gender[:Male]

Or with an Indifferent Hash-like syntax

    AuxCode.genders['Male']
    AuxCode.genders[:Male]
    AuxCode.genders.male

    Gender.male

    # these all return the same result
    Breed.find_by_name 'Golden Retriever'
    Breed['Golden Retriever']
    Breed[:golden_retriever]
    Breed.golden_retriever
    AuxCodes.breeds.golden_retriever

Read [the spec](http://github.com/remi/aux_codes/blob/master/spec/aux_code_spec.rb) to see other usage examples

TODO
----

 - make a spec specifically for showing off the different API features quickly and easily
 - convert this README to RDoc
 - make table name and column names configurable (but with strong defaults)
 - staticly typed fields?
 - fix bug discovered while screencasting ... Gender.male returned the female code (because it includes 'male')

NOTES
-----

this implementation is for ActiveRecord only!  i hope to eventually make a similar DataMapper implementation
