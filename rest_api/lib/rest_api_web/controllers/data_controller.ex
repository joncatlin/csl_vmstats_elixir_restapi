defmodule RestApiWeb.DataController do
    use RestApiWeb, :controller

    def index(conn, _params) do
      my_data = %{val1: %{"one" => "this is the first value", "two" => "this is the second value"},
                  val2: [1,2,3,4,5,6]}
      json conn, my_data
    end
end