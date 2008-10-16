aux codes
=========

Way back when, when I was learning database development, a mentor of mine showed me 
a technique that he liked to use to consolidate similar enumeration-esque database tables.

Often, applications have enumeration-esque tables that merely store simply key / value pairs, 
typically a unique ID and a string.  Take for instance, a 'gender' table:

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

    [ to be implemented ]
