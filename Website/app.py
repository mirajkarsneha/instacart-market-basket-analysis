import os
from flask import Flask, render_template, request, jsonify
from google.cloud import bigquery
import requests
import urllib.parse
from sqlalchemy import create_engine
import pandas as pd

# Use environment variables for sensitive data
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
        p.product_id,
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
        return None, None

    user_product_ids = result_df['product_id'].unique().tolist()
    grouped_df = result_df.groupby('order_id')['product_name'].apply(list).reset_index()
    grouped_df['image_urls'] = grouped_df['product_name'].apply(lambda products: [get_image_url(product) for product in products])
    return grouped_df, user_product_ids

def get_top_product_pairs():
    pair_combinations_query = """
    WITH CombinedOrders AS (
        SELECT order_id, product_id
        FROM `instacart-441209.instacart.order_products_prior`
        UNION ALL
        SELECT order_id, product_id
        FROM `instacart-441209.instacart.order_products_train`
    )

    SELECT
        p1.product_id AS product_id_1,
        p1.product_name AS product_name_1,
        p2.product_id AS product_id_2,
        p2.product_name AS product_name_2,
        COUNT(*) AS purchase_count
    FROM CombinedOrders co1
    JOIN CombinedOrders co2 ON co1.order_id = co2.order_id AND co1.product_id < co2.product_id
    JOIN `instacart-441209.instacart.products` p1 ON co1.product_id = p1.product_id
    JOIN `instacart-441209.instacart.products` p2 ON co2.product_id = p2.product_id
    GROUP BY p1.product_id, p1.product_name, p2.product_id, p2.product_name
    ORDER BY purchase_count DESC
    LIMIT 10;
    """
    pair_combinations_df = pd.read_sql(pair_combinations_query, engine)
    return pair_combinations_df

def get_recommendations(user_id):
    _, user_product_ids = get_ordered_and_carted_products(user_id)
    pair_combinations_df = get_top_product_pairs()

    recommendations = set()
    for _, row in pair_combinations_df.iterrows():
        if row['product_id_1'] not in user_product_ids:
            recommendations.add(row['product_name_1'])
        if row['product_id_2'] not in user_product_ids:
            recommendations.add(row['product_name_2'])

    if len(recommendations) < 5:
        additional_products = []
        for _, row in pair_combinations_df.iterrows():
            if row['product_id_1'] not in user_product_ids and row['product_name_1'] not in recommendations:
                additional_products.append(row['product_name_1'])
            if row['product_id_2'] not in user_product_ids and row['product_name_2'] not in recommendations:
                additional_products.append(row['product_name_2'])

        for product in additional_products:
            if len(recommendations) >= 5:
                break
            recommendations.add(product)

    return list(recommendations)[:5]

@app.route('/get-products', methods=['POST'])
def get_order_prediction():
    user_id = request.form.get('user_id')
    if not user_id:
        return jsonify({'error': 'User ID is required'}), 400
    
    grouped_df, user_product_ids = get_ordered_and_carted_products(user_id)
    if grouped_df is None:
        return jsonify({'error': 'No data found for the user'}), 404

    grouped_df = grouped_df.head(3)
    grouped_products = grouped_df.to_dict(orient='records')

    # Get recommended products
    recommended_products = get_recommendations(user_id)

    # Get images for recommended products
    recommended_products_images = [get_image_url(product) for product in recommended_products]

    return jsonify({
        'grouped_products': grouped_products,
        'recommended_products': recommended_products,
        'recommended_products_images': recommended_products_images
    })

# Method to predict the user's next order
def predict_next_order(user_id, top_n=10):
    user_order_freq_df = get_user_order_frequencies(user_id)
    next_order_prediction = user_order_freq_df[user_order_freq_df['reorder_count'] > 0]
    next_order_prediction = next_order_prediction.head(top_n)
    return next_order_prediction[['product_name', 'order_count', 'reorder_count']]

@app.route('/predict-next-order', methods=['POST'])
def predict_next_order_route():
    user_id = request.form.get('user_id')
    if not user_id:
        return jsonify({'error': 'User ID is required'}), 400
    
    predicted_next_order = predict_next_order(int(user_id))
    if predicted_next_order.empty:
        return jsonify({'error': 'No data found for the user'}), 404

    predicted_products = predicted_next_order.to_dict(orient='records')
    
    # Get images for predicted products
    predicted_products_images = [get_image_url(product['product_name']) for product in predicted_products]

    return jsonify({
        'predicted_next_order': predicted_products,
        'predicted_next_order_images': predicted_products_images
    })

@app.route('/')
def index():
    return render_template('index.html')

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5001)
