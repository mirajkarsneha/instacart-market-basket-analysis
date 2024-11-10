import os
from flask import Flask, render_template, request, jsonify
from google.cloud import bigquery
import requests
import pandas as pd
import urllib.parse

# Google API credentials and settings
api_key = "AIzaSyD4BCfPJwAnKQ5cd-Ip_0m7QXtva9JvDIM"  # Replace with your new API key
cx = "31d9e2af7c81642fb"  # Replace with your CSE ID

app = Flask(__name__)
project_id = 'instacart-441209'
client = bigquery.Client(project=project_id)

def get_image_url(product_name):
    # Google Custom Search API URL for image search
    encoded_query = urllib.parse.quote(product_name)
    url = f"https://www.googleapis.com/customsearch/v1?q={encoded_query}&cx={cx}&searchType=image&key={api_key}"
    response = requests.get(url)
    
    # Check response and extract image URL
    if response.status_code == 200:
        image_data = response.json()
        if 'items' in image_data and len(image_data['items']) > 0:
            return image_data['items'][0]['link']
    return None  # Return None if no image found

@app.route('/')
def home():
    return render_template('index.html')

@app.route('/get_order_prediction', methods=['POST'])
def get_order_prediction():
    try:
        user_id = request.form.get('user_id')
        
        # BigQuery to fetch reordered products for a specific user
        query = f"""
            SELECT 
                p.product_name,
                COUNT(*) AS order_count,
                SUM(CASE WHEN op.reordered = 1 THEN 1 ELSE 0 END) AS reorder_count
            FROM `instacart-441209.instacart.order_products_prior` op
            JOIN `instacart-441209.instacart.products` p ON op.product_id = p.product_id
            JOIN `instacart-441209.instacart.orders` o ON op.order_id = o.order_id
            WHERE o.user_id = {user_id}
            GROUP BY p.product_name
            ORDER BY reorder_count DESC
            LIMIT 10
        """
        
        # Execute query and convert to DataFrame
        result = client.query(query)
        df = result.to_dataframe()
        
        # Append image URLs for each product
        predictions = []
        for _, row in df.iterrows():
            product_name = row['product_name']
            image_url = get_image_url(product_name)
            predictions.append({
                "product_name": product_name,
                "order_count": row['order_count'],
                "reorder_count": row['reorder_count'],
                "image_url": image_url or ""  # Default to empty string if no image found
            })

        # Return JSON response
        return jsonify(predictions if predictions else {"message": "No data found for the given user_id."})
    
    except Exception as e:
        return jsonify({"error": str(e)})

@app.route('/predict_next_order/<user_id>', methods=['GET'])
def predict_next_order(user_id):
    try:
        # Replace this logic with your actual model prediction code
        query = f"""
            SELECT product_name
            FROM `instacart-441209.instacart.products`
            WHERE product_id IN (
                SELECT product_id
                FROM `instacart-441209.instacart.order_products_prior`
                WHERE order_id IN (
                    SELECT order_id
                    FROM `instacart-441209.instacart.orders`
                    WHERE user_id = {user_id}
                )
                ORDER BY RAND()
                LIMIT 5
            )
        """
        
        # Execute query and convert to DataFrame
        result = client.query(query)
        df = result.to_dataframe()

        # Append image URLs for each predicted product
        predictions = []
        for _, row in df.iterrows():
            product_name = row['product_name']
            image_url = get_image_url(product_name)
            predictions.append({
                "product_name": product_name,
                "image_url": image_url or ""  # Default to empty string if no image found
            })
        
        return jsonify(predictions if predictions else {"message": "No prediction available."})
    
    except Exception as e:
        return jsonify({"error": str(e)})

if __name__ == '__main__':
    app.run(debug=True)
