defmodule PastryChefTest.InstancesController do
  require OK
  use PastryChefTest.Web, :controller
  alias PastryChefTest.EC2, as: EC2

  def instances(conn, _param) do
    result = OK.with do
      response <- EC2.fetch_ec2_instances_info()
      instances_info = EC2.parse_instances_info(response)
      IO.inspect instances_info
      OK.success instances_info
    end
    case result do
      {:ok, term} ->
        render conn, instances: term
      {:error, term} ->
        render conn, message: "error: #{inspect(term)}"
    end
  end

  def instance(conn, %{"id" => id}) do
    result = OK.with do
      response <- EC2.fetch_ec2_instances_info(id)
      case EC2.parse_instances_info(response) do
        [ ] -> OK.failure "#{id} is not found..."
        [ instance_info | _ ] -> OK.success instance_info
      end
    end
    case result do
      {:ok, term} ->
        render conn, instance: term
      {:error, term} ->
        render conn, message: "error: #{inspect(term)}"
    end
  end

  def create(conn, params) do
    env = Application.get_env(:pastry_chef_test, PastryChefTest.InstanceController)
    branch1 = params["html-dump1"]
    branch2 = params["html-dump2"]
    name = params["name"]
    result = OK.with do
      tags = [{:html_dump1, branch1}, {:html_dump2, branch2}]
      response <- EC2.run_ec2_instance(env[:image_id], env[:key_name], name, tags)
      instance_id = EC2.parse_instance_id(response)
      IO.inspect instance_id
      _ <- EC2.wait_running(instance_id)
      IO.inspect "instance is running!"
      _ <- EC2.wait_status_ok(instance_id)
      dir = "/home/ec2-user/"
      EC2.deploy_ec2_instance(instance_id, env[:key_path], "echo '#{branch1} and #{branch2}' > #{dir}/index.html")
    end
    case result do
      {:ok, term} ->
        render conn, message: "success! branch1: #{branch1}, branch2: #{branch2}\n#{term} cat index.html"
      {:error, term} ->
        render conn, message: "error: #{inspect(term)}"
    end
  end

  def rename(conn, %{"id" => id, "name" => name}) do
    result = OK.with do
      EC2.update_ec2_instance_tags(id, [{:Name, name}])
    end
    case result do
      {:ok, _} ->
        render conn, message: "success! rename to #{name}"
      {:error, term} ->
        render conn, message: "error: #{inspect(term)}"
    end
  end

  def deploy(conn, params = %{"id" => id}) do
    env = Application.get_env(:pastry_chef_test, PastryChefTest.InstanceController)
    branch1 = params["html-dump1"]
    branch2 = params["html-dump2"]
    result = OK.with do
      dir = "/home/ec2-user/"
      response <- EC2.deploy_ec2_instance(id, env[:key_path], "echo '#{branch1} and #{branch2}' > #{dir}/index.html")
      tags = [{:html_dump1, branch1}, {:html_dump2, branch2}]
      _ <- EC2.update_ec2_instance_tags(id, tags)
      OK.success response
    end
    case result do
      {:ok, term} ->
        render conn, message: "success! branch1: #{branch1}, branch2: #{branch2}\n#{term} cat index.html"
      {:error, term} ->
        render conn, message: "error: #{inspect(term)}"
    end
  end

  def change_state(conn, %{"id" => id, "state" => state}) do
    result = case state do
      "start" -> EC2.start_ec2_instance(id)
      "stop" -> EC2.stop_ec2_instance(id)
      "terminate" -> EC2.terminate_ec2_instance(id)
      "" -> {:error, "undefined state"}
    end
    case result do
      {:ok, _term} ->
        render conn, message: "success!"
      {:error, term} ->
        render conn, message: "error: #{inspect(term)}"
    end
  end
end
