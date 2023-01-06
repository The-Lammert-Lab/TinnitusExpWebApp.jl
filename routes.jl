using Genie.Router

route("/") do
  serve_static_file("welcome.html")
end

route("/experiment") do 
  "Experiment page"
end

route("/start") do
  serve_static_file("start.html")
end

route("/experiment") do
  
end
