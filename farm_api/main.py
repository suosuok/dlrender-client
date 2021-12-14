from flask import Flask, request  # 引入request对象
app = Flask(__name__)


@app.route("/index", methods=["GET", "POST"])
def index():
    """
    my_json :return: dict 格式的数据
    """
    my_json = request.get_json()
    name = request.get_json().get("name")
    age = request.get_json().get("age")
    city = request.get_json().get("city")
    age += 100
    print_data(name, age, city)
    print (type(my_json))
    return my_json

@app.route("/status",methods=["GET"])
def status():
    data = {"status":"online","code":200}
    return data

@app.route("/")
def root():
    return "根目录，API测试用"


def print_data(*args):
    data = args
    print(data)

def run():
    app.run(host="0.0.0.0", port=5000)

if __name__ == '__main__':
    run()
