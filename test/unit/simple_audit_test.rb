require 'test_helper'

class SimpleAuditTest < ActiveSupport::TestCase

  include SimpleAudit  

  test "should audit entity creation" do
    assert_difference 'Audit.count', 4 do
      assert_difference 'Person.count', 2 do
        Person.create(:name => "Mihai Tarnovan", :email => "mihai.tarnovan@cubus.ro", :address => Address.new(:line_1 => "M. Viteazu nr. 11 sc. C ap.32"))
        Person.create(:name => "Gabriel Tarnovan", :email => "gabriel.tarnovan@cubus.ro", :address => Address.new(:line_1 => "Calea Lunga nr. 104 Sibiu 123500"))
      end
    end
  end
  
  test "should set correct action" do
    person = Person.create(:name => "Mihai Tarnovan", :email => "mihai.tarnovan@cubus.ro", :address => Address.new(:line_1 => "M. Viteazu nr. 11 sc. C ap.32"))
    assert_equal Audit.last.action, "create"
    person.name = "Mihai T."
    person.save
    assert_equal person.audits.last.action, "update"
  end
  
  test "should audit only given fields" do
    person = Person.create(:name => "Mihai Tarnovan", :email => "mihai.tarnovan@cubus.ro", :address => Address.new(:line_1 => "M. Viteazu nr. 11 sc. C ap.32"))
    create_audit = person.audits.last
    assert_difference 'Audit.count', 1 do
      person.email = "mihai.tarnovan@gmail.com"
      person.save
    end
    update_audit = person.audits.last
    assert_equal update_audit.delta(create_audit), {}
  end
  
  test "should audit associated entity changes" do
    person = Person.create(:name => "Mihai Tarnovan", :email => "mihai.tarnovan@cubus.ro", :address => Address.new(:line_1 => "M. Viteazu nr. 11 sc. C ap.32", :zip => "550350"))
    create_audit = person.audits.last
    assert_difference 'person.audits.count', 1 do
      person.address = Address.new(:line_1 => "Bdul. Victoriei nr. 51", :zip => "550150")
      person.name = "Gigi Kent"
      person.email = "gigi@kent.ro"
      person.save
    end
    update_audit = person.audits.last    
    assert_equal update_audit.delta(create_audit), { 
      :name => ["Mihai Tarnovan", "Gigi Kent"], 
      :address => [
        { :line_1 => "M. Viteazu nr. 11 sc. C ap.32", :zip => "550350" }, 
        { :line_1 => "Bdul. Victoriei nr. 51", :zip => "550150" }
      ]
    }
  end
  
  test "should audit all attributes by default" do
    address = Address.create
    differences = Address.attribute_names.map(&:to_s).sort - Audit.last.change_log.keys.map(&:to_s).sort
    assert_equal 0, differences.length
  end

  test "should not create audit if block returns falsy value" do
    secretive_person = SecretivePerson.create(:name => "Mihai Tarnovan", :email => "mihai.tarnovan@cubus.ro", :address => Address.new(:line_1 => "M. Viteazu nr. 11 sc. C ap.32", :zip => "550350"))
    secretive_person.update_attributes name: "Jim bob"
    secretive_person.update_attributes address: Address.new(:line_1 => "Whitehouse", :zip => "12345")
    secretive_person.update_attributes name: "Marky Mark"
    assert_equal 2, secretive_person.audits.length
  end

  test "should use proper username method" do
    address = HomeAddress.create
    assert_equal User.new.short_name, address.audits.last.username
    address = Address.create
    assert_equal User.new.full_name, address.audits.last.username
  end
   
end