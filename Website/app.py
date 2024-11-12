import os
from flask import Flask, render_template, request, jsonify
from google.cloud import bigquery
import requests
import urllib.parse
from sqlalchemy import create_engine
from collections import defaultdict

# Use environment variables for sensitive data
#api_key = os.getenv("AIzaSyB5ePyLzzs6TKU1a_ffV0E4EhkKK2uoaLs")  # Set the environment variable in your system
#cx = os.getenv("31d9e2af7c81642fb")  # Set the environment variable in your system
api_key = os.getenv("GOOGLE_API_KEY")
cx = os.getenv("GOOGLE_CX")

# Initialize Flask app
app = Flask(__name__)

# Google Cloud and BigQuery setup
project_id = 'instacart-441209'
client = bigquery.Client(project=project_id)

# BigQuery engine setup for SQLAlchemy
DATABASE_URI = f'bigquery://{project_id}'
engine = create_engine(DATABASE_URI)


# Cache to avoid repeated API calls
image_url_cache = {}

def get_image_url(product_name):
    if product_name in image_url_cache:
        return image_url_cache[product_name]
    
    query = f"{product_name} Instacart grocery"
    url = f"https://www.googleapis.com/customsearch/v1?q={urllib.parse.quote(query)}&cx={cx}&searchType=image&key={api_key}"
    
    try:
        response = requests.get(url)
        response.raise_for_status()
        data = response.json()
        image_url = data['items'][0]['link'] if 'items' in data else "https://via.placeholder.com/100"
        image_url_cache[product_name] = image_url
        return image_url
    except Exception as e:
        print(f"Error fetching image for {product_name}: {e}")
        return "https://via.placeholder.com/100"

def get_ordered_and_carted_products(user_id):
    combined_query = f"""
    WITH CombinedOrderProducts AS (
        SELECT order_id, product_id
        FROM `instacart-441209.instacart.order_products_prior`
        UNION ALL
        SELECT order_id, product_id
        FROM `instacart-441209.instacart.order_products_train`
    )
    SELECT 
        o.user_id,
        o.order_id,
        p.product_name
    FROM CombinedOrderProducts op
    JOIN `instacart-441209.instacart.products` p ON op.product_id = p.product_id
    JOIN `instacart-441209.instacart.orders` o ON op.order_id = o.order_id
    WHERE o.user_id = {user_id}
    ORDER BY o.order_id, p.product_name;
    """
    query_job = client.query(combined_query)
    result_df = query_job.to_dataframe()

    if result_df.empty:
        return None
    
    grouped_df = result_df.groupby('order_id')['product_name'].apply(list).reset_index()
    grouped_df['image_urls'] = grouped_df['product_name'].apply(lambda products: [get_image_url(product) for product in products])
    return grouped_df

@app.route('/get-products', methods=['POST'])
def get_order_prediction():
    user_id = request.form.get('user_id')
    if not user_id:
        return jsonify({'error': 'User ID is required'}), 400
    
    grouped_df = get_ordered_and_carted_products(user_id)
    if grouped_df is None:
        return jsonify({'error': 'No data found for the user'}), 404

    grouped_df = grouped_df.head(3)
    grouped_products = grouped_df.to_dict(orient='records')
    return jsonify({'grouped_products': grouped_products})

@app.route('/')
def index():
    return render_template('index.html')

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5001)

