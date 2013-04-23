require "spec_helper"

describe RestfulSync::ApiController do
  before(:each) do
    Nestful.stub(:send) { "test" }

    @user_attributes = { "email" => "test@test.com" }

    
    @products = []
    @properties = []
    @user = TestUser.new @user_attributes
    names = %w(name1 name2)
    names.each_with_index do |name, i|
      product = TestProduct.new name: name

      property = TestProperty.create(name: name)

      product.properties << property

      @products << product
      @properties << property
    end
  end

  describe "POST #create" do
    context "simple model" do
      it "posts with no params and returns 404" do
        post :create, use_route: :restful_sync, model: @user.class.to_s, api: {}
      
        response.code.should eq("404")
      end

      it "posts with valid params and returns 200" do
        count = TestUser.count

        post :create, use_route: :restful_sync, model: @user.class.to_s, api: RestfulSync::ApiNotifier.decorated(@user).as_json

        response.code.should eq("200")
        TestUser.count.should > count
      end
    end

    context "embedded models" do
      it "posts with valid params and returns 200" do
        count = TestUser.count        
        @user.products = @products

        post :create, use_route: :restful_sync, model: @user.class.to_s, api: RestfulSync::ApiNotifier.decorated(@user).as_json

        response.code.should eq("200")
        TestUser.count.should > count
      end
    end
  end

  describe "PUT #update" do
    context "simple model" do
      it "updates with no id and returns 404" do
        put :update, use_route: :restful_sync, model: @user.class.to_s, api: {}
      
        response.code.should eq("404")
      end

      it "updates with params and returns 200" do
        @user.save
        put :update, use_route: :restful_sync, model: @user.class.to_s, api: RestfulSync::ApiNotifier.decorated(@user).as_json, id: @user.id
      
        response.code.should eq("200")
      end

      it "updates with changed params and returns 200" do
        email = "changed@test.com"
        @user.save
        @user.email = email
        post :create, use_route: :restful_sync, model: @user.class.to_s, api: RestfulSync::ApiNotifier.decorated(@user).as_json

        response.code.should eq("200")
        TestUser.first.email.should eq(email)
      end
    end

    context "embedded models" do
      it "updates with valid params and returns 200" do
        name = "changed_product"
        @products.first.name = name
        @user.products = @products

        post :create, use_route: :restful_sync, model: @user.class.to_s, api: RestfulSync::ApiNotifier.decorated(@user).as_json

        response.code.should eq("200")
        TestUser.first.products.all.map(&:name).should include(name)
      end
    end
  end

  describe "DELETE #destroy" do
    context "simple model" do
      it "deletes with no id and returns 404" do
        delete :destroy, use_route: :restful_sync, model: @user.class.to_s
      
        response.code.should eq("404")
      end

      it "deletes with wrong id and returns 404" do
        @user.save
        delete :destroy, use_route: :restful_sync, model: @user.class.to_s, api: RestfulSync::ApiNotifier.decorated(@user).as_json, id: (@user.id + 1)
      
        response.code.should eq("404")
        TestUser.count.should eq(1)
      end

      it "deletes with good id and returns 200" do
        @user.save
        delete :destroy, use_route: :restful_sync, model: @user.class.to_s, api: RestfulSync::ApiNotifier.decorated(@user).as_json, id: @user.id
      
        response.code.should eq("200")
        TestUser.count.should eq(0)
      end
    end

    context "embedded models" do
      it "deletes embedded models" do
        @user.products = @products
        @user.save
        delete :destroy, use_route: :restful_sync, model: @user.class.to_s, api: RestfulSync::ApiNotifier.decorated(@user).as_json, id: @user.id   

        response.code.should eq("200")
        TestUser.count.should eq(0)
        TestProduct.count.should eq(0)
      end
    end
  end
end