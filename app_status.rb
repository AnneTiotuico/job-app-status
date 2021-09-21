require "sinatra"
require "sinatra/reloader" if development?
require "tilt/erubis"
require "sinatra/content_for"

configure do
  set :erb, :escape_html => true
  enable :sessions
  set :session_secret, 'secret'
end

before do 
  session[:applications] ||= []
end

helpers do 
  def app_category(category)
    session[:applications].select do |app|
      app[:status] == category
    end
  end
  
  def selected_status(app, status)
    app[:status] == status ? "selected" : ""
  end
end

def next_element_id(elements)
  max = elements.map { |element| element[:id] }.max || 0
  max + 1
end

def load_app(id)
  app = session[:applications].find { |app| app[:id] == id }
  return app if app

  session[:error] = "The specified application was not found."
  redirect "/applications"
end

get "/" do
  redirect "/applications"
end

# View list of applications
get "/applications" do
  @categories = ["applied", "interviewing", "offered", "no"]
  erb :index
end

# Render new application form
get "/applications/new" do
  erb :new_app
end

# Add a new appplication
post "/applications" do
  @date = params["date-applied"]
  @company = params["company"]
  @position = params["position"]
  @url = params["url"]
  @status = params["status"]
  @id = next_element_id(session[:applications])
  session[:applications] << { id: @id, date: @date, company: @company, position: @position, 
                              url: @url, status: @status, notes: "" }
  session[:message] = "The application has been added."
  redirect "/applications"
end

# Display applications in specific category
get "/applications/:category" do |category|
  @apps_by_category = app_category(category)
  
  erb :category
end

# Edit an exisiting application
get "/applications/:id/edit" do |id|
  id = id.to_i
  @app = load_app(id)
  erb :edit_app
end

# Make changes to exisiting application
post "/applications/:id/edit" do |id|
  id = id.to_i
  app = load_app(id)
  
  app[:date] = params["date-applied"]
  app[:company] = params["company"]
  app[:position] = params["position"]
  app[:url] = params["url"]
  app[:status] = params["status"]

  session[:message] = "The application details have been updated and has been 
                        moved to #{params["status"].capitalize}."
  redirect "/applications"
end


# Delete an exisiting application
post "/applications/:id/delete" do |id|
  id = id.to_i
  session[:applications].reject! { |app| app[:id] == id }
  session[:message] = "The application has been deleted."
  redirect "/applications"

end

# Render notes form
get "/applications/:id/notes" do |id|
  id = id.to_i
  @app = load_app(id)
  erb :notes
end

# Add notes to exisiting application
post '/applications/:id/notes' do |id|
  id = id.to_i
  app = load_app(id)
  app[:notes] = params[:notes]
  session[:message] = "Notes have been saved to #{app[:company]}"
  redirect "/applications/#{app[:status]}"
end