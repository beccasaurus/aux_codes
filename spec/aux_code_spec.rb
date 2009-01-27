require File.dirname(__FILE__) + '/spec_helper'

describe AuxCode do

  it 'should require a name' do
    AuxCode.create( :name => nil ).should_not be_valid
    AuxCode.create( :name => ' ' ).should_not be_valid
    AuxCode.create( :name => 'foo' ).should be_valid
  end

  it 'should have many aux codes (if category)' do
    code = AuxCode.create! :name => 'foo'
    code.codes.should be_empty
    w00t = code.codes.create :name => 'w00t'
    code.codes.should include(w00t)
  end
  
  it 'should have code names (if category)' do
    code = AuxCode.create! :name => 'foo'
    code.codes.create :name => 'chunky'
    code.codes.create :name => 'bacon'
    
    code.codes.length.should == 2
    code.code_names.length.should == 2
    code.code_names.should include('chunky')
    code.code_names.should include('bacon')
  end

  it "should know whether it's a category or a category value / code" do
    code = AuxCode.create! :name => 'foo'
    w00t = code.codes.create :name => 'w00t'

    w00t.is_a_category?.should be_false
    code.is_a_category?.should be_true
  end

  it 'should belong to a category (if not a category)' do
    code = AuxCode.create! :name => 'foo'
    w00t = code.codes.create! :name => 'w00t'
    w00t.aux_code.should == code
    w00t.code.should == code
    w00t.category.should == code
    w00t.category.codes.should include(w00t)

    w00t.codes.should be_empty
    code.category.should be_nil
  end

  it 'should require a name unique to category' do
    first_category  = AuxCode.create! :name => 'foo'
    second_category = AuxCode.create! :name => 'bar'

    first_category.aux_codes.create( :name => 'w00t' ).should be_valid
    first_category.aux_codes.create( :name => 'w00t' ).should_not be_valid
    second_category.aux_codes.create( :name => 'w00t' ).should be_valid
  end

  it 'should be able to easily get all categories' do
    AuxCode.categories.should be_empty

    first_category  = AuxCode.create! :name => 'foo'
    second_category = AuxCode.create! :name => 'bar'
    code_1 = first_category.codes.create :name => 'w00t'
    code_2 = first_category.codes.create :name => 'w00t'

    AuxCode.categories.should include(first_category)
    AuxCode.categories.should include(second_category)
    AuxCode.categories.should_not include(code_1)
    AuxCode.categories.should_not include(code_2)
  end

  it 'should be able to easily get all category names' do
    AuxCode.category_names.should be_empty

    first_category  = AuxCode.create! :name => 'foo'
    second_category = AuxCode.create! :name => 'bar'
    code_1 = first_category.codes.create :name => 'w00t'

    AuxCode.category_names.should include('foo')
    AuxCode.category_names.should include('bar')
    AuxCode.category_names.should_not include('w00t')
  end

  it 'should be able to fetch a category give the category, its name, or its id' do
    cat  = AuxCode.create! :name => 'foo'
    AuxCode.category( cat ).should == cat
    AuxCode.category( cat.id ).should == cat
    AuxCode.category( cat.name ).should == cat
    AuxCode.category( cat.name.to_sym ).should == cat
  end

  it 'should be able to easily get all values (codes) for a category' do
    first_category  = AuxCode.create! :name => 'foo'
    code_1 = first_category.codes.create :name => 'w00t'
    code_2 = first_category.codes.create :name => 'chunky'
    code_3 = first_category.codes.create :name => 'bacon'
    
    [ AuxCode.category_values( first_category ), AuxCode.category_values( 'foo' ) ].each do |codes|
      codes.should include(code_1)
      codes.should include(code_2)
      codes.should include(code_3)
      codes.should_not include(first_category)
    end
    AuxCode.category_values( first_category ).should == AuxCode.category_codes( first_category )
  end

  it 'should be able to easily get all value names (code names) for a category' do
    first_category  = AuxCode.create! :name => 'foo'
    code_1 = first_category.codes.create :name => 'w00t'
    code_2 = first_category.codes.create :name => 'chunky'
    code_3 = first_category.codes.create :name => 'bacon'
    
    [ AuxCode.category_code_names( first_category ), AuxCode.category_code_names( 'foo' ) ].each do |codes|
      codes.should include('w00t')
      codes.should include('chunky')
      codes.should include('bacon')
      codes.should_not include('foo')
    end
  end

  it 'should be able to get a Class for each category' do
    random_category = AuxCode.create! :name => 'random-category-name'
    foo_category = AuxCode.create! :name => 'foo'
    foo_class = foo_category.aux_code_class
    foo_class.count.should == 0

    x = foo_category.codes.create :name => 'chunky'
    foo_class.count.should == 1

    foo_class.create :name => 'bacon'
    foo_class.count.should == 2

    foo = foo_class.create! :name => 'foo'
    foo_class.count.should == 3

    bar = foo_class.new :name => 'bar'
    bar.save
    foo_class.count.should == 4

    w00t = foo_class.new :name => 'w00t'
    w00t.save!
    foo_class.count.should == 5

    foo_class.find( :first, :conditions => ['name = ?', 'foo'] ).should == foo
    foo_class.find( :first, :conditions => ['name = ?', 'foo'] ).should_not == foo_category

    foo_class.find_by_name( 'foo' ).should == foo
    foo_class.find_by_name( 'foo' ).should_not == foo_category

    foo_class.find_all_by_name( 'foo' ).should include(foo)
    foo_class.find_all_by_name( 'foo' ).should_not include(foo_category)

    foo_class.all.should include(foo)
    foo_class.all.should_not include(foo_category)

    foo_class.find_by_name( 'neat' ).should be_nil
    foo_class.find_or_create_by_name( 'neat' ).should_not be_nil
    foo_class.find_by_name( 'neat' ).should_not be_nil
    foo_class.code_names.should include('neat')
  end

  it 'should create good class names from category names for #create_classes!' do
    AuxCode.new( :name => 'foos' ).class_name.should == 'Foo'
    AuxCode.new( :name => 'foo Bars' ).class_name.should == 'FooBar'
    AuxCode.new( :name => 'foo Bar lar Tars' ).class_name.should == 'FooBarLarTar'
    AuxCode.new( :name => 'foo_Bar lar-Tars' ).class_name.should == 'FooBarLarTar'
    AuxCode.new( :name => 'foo_Bar0lar1Tar5s' ).class_name.should == 'FooBarLarTar'
    AuxCode.new( :name => 'Dog' ).class_name.should == 'Dog'
    AuxCode.new( :name => 'Dogs' ).class_name.should == 'Dog'
  end

  it 'should be able to get categories and their values using Hash syntax' do
    foo_category = AuxCode.create! :name => 'foo'
    bar_category = AuxCode.create! :name => 'bar'
    chunky = foo_category.codes.create :name => 'chunky'
    bacon  = foo_category.codes.create :name => 'bacon'
    
    AuxCode['foo'].should == foo_category
    AuxCode[:foo].should == foo_category
    
    AuxCode['foo'][:chunky].should == chunky
    AuxCode[:foo]['chunky'].should == chunky
  end

  it 'should be able to get categories and their values using indifferent Hash syntax' do
    foo_category = AuxCode.create! :name => 'foo'
    bar_category = AuxCode.create! :name => 'bar'
    chunky = foo_category.codes.create :name => 'chunky'
    bacon  = foo_category.codes.create :name => 'bacon'
    
    AuxCode.foo.should == foo_category
    AuxCode.foo.chunky.should == chunky
  end

  it 'should be able to handle names with spaces (with Hash syntax)' do
    foo_category = AuxCode.create! :name => 'foo'
    bar_category = AuxCode.create! :name => 'bar'
    chunky = foo_category.codes.create :name => 'I am Chunky'
    bacon  = foo_category.codes.create :name => 'Yay for Bacon'

    foo_category.i_am_chunky.should == chunky
    foo_category[:yay_for_bacon].should == bacon
  end

  it 'an aux_code_class should raise a NoMethodError, as per usual, if an undefined method is called' do
    chunky = AuxCode.create!( :name => 'chunky' ).aux_code_class
    lambda { chunky.new.bacon }.should raise_error(NoMethodError)
  end

  it 'should be able to pass a block to aux_code_class for quick and easy class customization' do
    chunky = AuxCode.create!( :name => 'chunky' ).aux_code_class do
      def bacon
        "chunky bacon!"
      end
    end
    lambda { chunky.new.bacon }.should_not raise_error(NoMethodError)
    chunky.new.bacon.should == 'chunky bacon!'
  end

  it 'should be able to pass a block to aux_code_class for quick and easy eigenclass customization' do
    chunky = AuxCode.create!( :name => 'chunky' ).aux_code_class do
      def self.bacon
        "chunky bacon!"
      end
    end
    chunky.bacon.should == 'chunky bacon!'
    lambda { chunky.new.bacon }.should raise_error(NoMethodError) # bacon is a class method
  end

  it 'should be able to define a meta attribute' do
    breed = AuxCode.create!( :name => 'breed' ).aux_code_class do
      attr_meta :acronym
    end

    apbt = breed.create :name => 'American Pit Bull Terrier', :acronym => 'APBT'
    breed.find_by_name('American Pit Bull Terrier').should == apbt
    breed.find_by_name('American Pit Bull Terrier').acronym.should == 'APBT'
  end

  it 'should be able to define multiple meta attributes'

  it 'should not be able to define a meta attribute of not configured'

  it 'should be able to define a strongly typed attribute'

  it 'should not be able to define a strongly typed attribute of not configured'

  it 'to_s should return the name of an aux_code' do
    AuxCode.new( :name => 'i Am the Name' ).to_s.should == 'i Am the Name'

    x = AuxCode.create :name => 'foo'
    y = x.codes.create :name => 'bar'
    x.to_s.should == 'foo'
    y.to_s.should == 'bar'
  end
    
  it 'should be able to load AuxCodes from a Hash' do
    AuxCode.count.should == 0
    AuxCode.load({
      
      # symbol => String Array
      :days => %w( Monday Tuesday Wednesday ),

      # symbol => Hash
      :colors => {
        
        # symbol => Hash options
        :red  => { :first_letter => 'r' },
        :blue => { :first_letter => 'b' }

      },

      # symbol => Array of hashes
      :foods => [
        { :name => 'Pizza', :taste => 'good' },
        { :name => 'Dirt', :taste => 'bad' }
      ],

      'Snack Foods' => %w( Popcorn chips )

    })

    AuxCode.category_names.should include('days')
    AuxCode.category_names.should include('colors')
    AuxCode.category_names.should include('foods')

    AuxCode[:days].codes.length.should == 3
    AuxCode[:days].code_names.should include('Monday')
    AuxCode[:days].monday.name.should == 'Monday'
    AuxCode[:days][:monday].name.should == 'Monday'

    AuxCode[:colors][:red].name.should == 'red'
    AuxCode[:colors][:red].first_letter.should == 'r'

    AuxCode[:colors].aux_code_class.red.name.should == 'red'
    AuxCode[:colors].aux_code_class.red.first_letter.should == 'r'
    AuxCode[:colors].aux_code_class[:red].first_letter.should == 'r'

    AuxCode.foods.pizza.taste.should == 'good'
    AuxCode.foods.dirt.taste.should == 'bad'

    AuxCode['Snack Foods'].codes.length.should == 2
    AuxCode.category('Snack Foods').codes.length.should == 2
    AuxCode.snack_foods.codes.length.should == 2
    AuxCode.snack_foods.code_names.should include('Popcorn')
    AuxCode.snack_foods[:popcorn].name.should == 'Popcorn'
    AuxCode[:snack_foods].popcorn.name.should == 'Popcorn'
    AuxCode['Snack Foods'].popcorn.name.should == 'Popcorn'

  end

  it 'should be able to load AuxCodes from a Yaml string' do
    require 'yaml'
    AuxCode.count.should == 0
    yaml = {
      
      # symbol => String Array
      :days => %w( Monday Tuesday Wednesday ),

      # symbol => Hash
      :colors => {
        
        # symbol => Hash options
        :red  => { :first_letter => 'r' },
        :blue => { :first_letter => 'b' }

      },

      # symbol => Array of hashes
      :foods => [
        { :name => 'Pizza', :taste => 'good' },
        { :name => 'Dirt', :taste => 'bad' }
      ],

      'Snack Foods' => %w( Popcorn chips )

    }.to_yaml
    AuxCode.load_yaml yaml

    AuxCode.category_names.should include('days')
    AuxCode[:days].code_names.should include('Monday')
    AuxCode[:days][:monday].name.should == 'Monday'
    AuxCode[:colors][:red].name.should == 'red'
    AuxCode[:colors][:red].first_letter.should == 'r'
    AuxCode[:colors].aux_code_class.red.first_letter.should == 'r'
    AuxCode.foods.pizza.taste.should == 'good'
    AuxCode.category('Snack Foods').codes.length.should == 2
    AuxCode.snack_foods.code_names.should include('Popcorn')
    AuxCode.snack_foods[:popcorn].name.should == 'Popcorn'
  end
  
  it 'should be able to load AuxCodes from a Yaml file' do
    AuxCode.count.should == 0

    AuxCode.load_file File.dirname(__FILE__) + '/example_aux_codes.yml'

    AuxCode.category_names.should include('days')
    AuxCode[:days].code_names.should include('Monday')
    AuxCode[:days][:monday].name.should == 'Monday'
    AuxCode[:colors][:red].name.should == 'red'
    AuxCode[:colors][:red].first_letter.should == 'r'
    AuxCode[:colors].aux_code_class.red.first_letter.should == 'r'
    AuxCode.foods.pizza.taste.should == 'good'
    AuxCode.category('Snack Foods').codes.length.should == 2
    AuxCode.snack_foods.code_names.should include('Popcorn')
    AuxCode.snack_foods[:popcorn].name.should == 'Popcorn'
  end

  it 'should be able to update meta attribute easily' do
    AuxCode.load_file File.dirname(__FILE__) + '/more_example_aux_codes.yml'
    AuxCode.foods.pizza.taste.should == 'good'
    AuxCode.foods.pizza.taste = 'yummy'
    AuxCode.foods.pizza.taste.should == 'yummy'
  end

  it 'should be able to load AuxCodes from a [slightly different] Yaml file' do
    AuxCode.count.should == 0

    AuxCode.load_file File.dirname(__FILE__) + '/more_example_aux_codes.yml'

    AuxCode.category_names.should include('days')
    AuxCode[:days].code_names.should include('Monday')
    AuxCode[:days][:monday].name.should == 'Monday'
    AuxCode[:colors][:red].name.should == 'red'
    AuxCode[:colors][:red].first_letter.should == 'r'
    AuxCode[:colors].aux_code_class.red.first_letter.should == 'r'
    AuxCode.foods.pizza.taste.should == 'good'
    AuxCode.category('Snack Foods').codes.length.should == 2
    AuxCode.snack_foods.code_names.should include('Popcorn')
    AuxCode.snack_foods[:popcorn].name.should == 'Popcorn'

    # quick test - overridable ...

    AuxCode.load({
      :colors => { 
        :red => { :first_letter => 'CHANGED' } 
      }
    })
    AuxCode[:colors][:red].first_letter.should == 'CHANGED'
  end

end
