# README
This is a  project for implementing the gem **paper_trails** into a N:N relationhip table.

For POC purposes, in this project we use 3 entities:
1. Group
2. Partner
3. PartnerGroup
    - This table keeps references to Group ID and Partner ID
    - This table is the main and only entity we are interested on keeping track using paper trails.


## Setup
Here are the steps to follow in order to replicate this POC 

1. run rails new project -d=[DB]
2. run rails generate model (for required model(s))
3. run rails db:create
4. run rails db:migrate
5. Validate database and entities exist and are correct
6. Add paper_trail get to gemfile (During the process of creating this POC, using gem version is preferred.)
7. run: 
    - bundle install
    - bundle exec rails generate paper_trail:install
    - bundle exec rake db:migrate
8. Validate Schema.rb to make sure versions table have been created
9. Add "has_paper_trail" to desired models
10. test and have fun


## Test example
**Create Partner object**

```ruby
irb(main):001:0> Partner.create(:name => "Test partner")
   (0.4ms)  SET NAMES utf8,  @@SESSION.sql_mode = CONCAT(CONCAT(@@sql_mode, ',STRICT_ALL_TABLES'), ',NO_AUTO_VALUE_ON_ZERO'),  @@SESSION.sql_auto_is_null = 0, @@SESSION.wait_timeout = 2147483
   (0.2ms)  BEGIN
  Partner Create (0.4ms)  INSERT INTO `partners` (`name`, `created_at`, `updated_at`) VALUES ('Test partner', '2022-04-15 21:01:10', '2022-04-15 21:01:10')
   (0.9ms)  COMMIT
=> #<Partner id: 1, name: "Test partner", created_at: "2022-04-15 21:01:10", updated_at: "2022-04-15 21:01:10">
```

**Create a Group object**

```ruby
irb(main):002:0> Group.create(:name => "test group")
   (0.2ms)  BEGIN
  Group Create (0.6ms)  INSERT INTO `groups` (`name`, `created_at`, `updated_at`) VALUES ('test group', '2022-04-15 21:01:29', '2022-04-15 21:01:29')
   (0.7ms)  COMMIT
=> #<Group id: 1, name: "test group", created_at: "2022-04-15 21:01:29", updated_at: "2022-04-15 21:01:29">
```

**Query the objects**

```ruby
irb(main):003:0> partner = Partner.find 1
  Partner Load (0.4ms)  SELECT  `partners`.* FROM `partners` WHERE `partners`.`id` = 1 LIMIT 1
=> #<Partner id: 1, name: "Test partner", created_at: "2022-04-15 21:01:10", updated_at: "2022-04-15 21:01:10">
irb(main):004:0> group = Group.find 1
  Group Load (0.4ms)  SELECT  `groups`.* FROM `groups` WHERE `groups`.`id` = 1 LIMIT 1
=> #<Group id: 1, name: "test group", created_at: "2022-04-15 21:01:29", updated_at: "2022-04-15 21:01:29">
```
**Create PartnerGroup object**

```ruby
irb(main):006:0> PartnerGroup.create(:partner => partner, :group => group)
   (0.2ms)  BEGIN
  PartnerGroup Create (0.3ms)  INSERT INTO `partner_groups` (`group_id`, `partner_id`, `created_at`, `updated_at`) VALUES (1, 1, '2022-04-15 21:02:24', '2022-04-15 21:02:24')
  PaperTrail::Version Create (0.4ms)  INSERT INTO `versions` (`item_type`, `item_id`, `event`, `created_at`) VALUES ('PartnerGroup', 1, 'create', '2022-04-15 21:02:24')
   (3.4ms)  COMMIT
=> #<PartnerGroup id: 1, group_id: 1, partner_id: 1, created_at: "2022-04-15 21:02:24", updated_at: "2022-04-15 21:02:24">
```
since PartnerGroup is the model that we have configured to use paper trails, here we can see traces of the gem doing the magic

**Query PartnerGroup object**

```ruby
irb(main):008:0> pg = PartnerGroup.find 1
  PartnerGroup Load (0.6ms)  SELECT  `partner_groups`.* FROM `partner_groups` WHERE `partner_groups`.`id` = 1 LIMIT 1
=> #<PartnerGroup id: 1, group_id: 1, partner_id: 1, created_at: "2022-04-15 21:02:24", updated_at: "2022-04-15 21:02:24">
```

**Query versions for given object**

```ruby
irb(main):009:0> pg.versions
  PaperTrail::Version Load (0.4ms)  SELECT  `versions`.* FROM `versions` WHERE `versions`.`item_id` = 1 AND `versions`.`item_type` = 'PartnerGroup' ORDER BY `versions`.`created_at` ASC, `versions`.`id` ASC LIMIT 11
=> #<ActiveRecord::Associations::CollectionProxy [#<PaperTrail::Version id: 1, item_type: "PartnerGroup", item_id: 1, event: "create", whodunnit: nil, object: nil, created_at: "2022-04-15 21:02:24">]>
irb(main):010:0> 
```


##  Author attribute
**Before getting to the author attribute, please read my clarification in the chat.**

Setting author attribute when we update records (Considering we will only have a single partner)

```ruby
class PartnerGroup < ApplicationRecord
  has_paper_trail

  belongs_to :group
  belongs_to :partner

  def before_update do
    set_paper_trail_author()
  end

  private 

  def set_paper_trail_author()
    PaperTrail.request.whodunnit = get_author()
  end

  def get_author()
    # find a way to get the correct author
    "Default user"
  end  
end

 
```

Setting author attribute when we delete all existing records in order to create new records (Considering we keep multiple partners for a group)
Since we wouldn't be updating the entity I would suggest to add a method to the class, like:
```ruby
 class PartnerGroup < ApplicationRecord
  has_paper_trail

  belongs_to :group
  belongs_to :partner

  def update_partners_for_group(partners)
    PaperTrail.request.whodunnit = "author" # get author info 

    # delete existing records

    # create new records based on partners parameter
  end
end
```

## Results of POC and research (personal opinion)
- Paper trail gem implementation is pretty straightforward and make a lot of sense for simple entities. For models like PartnerGroup (in this POC) depends on whether or not we are updating records or deleting + recreating, that decision changes everything for me.
- If deleting + recreating is the way to go we may want to explore the idea of adding a new layer (discuss in the chat)
- Regarding the whodunnit attribute (author of the change), I personally would avoid setting this value at controller level or at any level except for the model itself. If we want to keep some granularity and avoid concurrent issues (if any) making sure that we configure the whodunnit attribute at the model level is the way to go.
- If we need to delete + recreate we could also use before_create and before_destroy (as described in the code above for before_update) however I find this approach a little messy when we try to read the versions history and make sense of how changes occured.