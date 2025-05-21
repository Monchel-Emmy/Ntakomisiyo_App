<?php
// Simple PHP API for NtaKomisiyo

// Start session
session_start();

$host = 'fdb1028.awardspace.net';
$user = '4560324_park';
$pass = 'BLdEkCv@KedRkf9'; // your DB password
$db = '4560324_park';

$conn = new mysqli($host, $user, $pass, $db);
if ($conn->connect_error) {
    die(json_encode(['success' => false, 'message' => 'Database connection failed']));
}

// Create categories table if it doesn't exist
$create_categories_table = "CREATE TABLE IF NOT EXISTS categories (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL UNIQUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
)";

if (!$conn->query($create_categories_table)) {
    error_log("Error creating categories table: " . $conn->error);
}

$action = $_GET['action'] ?? '';

function response($data) {
    header('Content-Type: application/json');
    echo json_encode($data);
    exit;
}

if ($action === 'get_users') {
    try {
        error_log("get_users action started");
        
        // Get admin user ID from request
        $admin_id = $_GET['admin_id'] ?? '';
        error_log("Admin ID from request: " . $admin_id);
        
        if (empty($admin_id)) {
            error_log("Admin ID is empty");
            response(['success' => false, 'message' => 'Admin ID is required']);
            exit;
        }

        // Verify admin status
        $stmt = $conn->prepare("SELECT is_admin FROM users WHERE id = ?");
        if (!$stmt) {
            error_log("Prepare failed for admin check: " . $conn->error);
            response(['success' => false, 'message' => 'Database error: ' . $conn->error]);
            exit;
        }

        $stmt->bind_param("i", $admin_id);
        if (!$stmt->execute()) {
            error_log("Execute failed for admin check: " . $stmt->error);
            response(['success' => false, 'message' => 'Failed to execute query: ' . $stmt->error]);
            exit;
        }

        $result = $stmt->get_result();
        if (!$result) {
            error_log("Failed to get result for admin check");
            response(['success' => false, 'message' => 'Failed to get result']);
            exit;
        }

        $user = $result->fetch_assoc();
        error_log("Admin check result: " . print_r($user, true));

        if (!$user || $user['is_admin'] != 1) {
            error_log("User is not admin or not found");
            response(['success' => false, 'message' => 'Unauthorized access']);
            exit;
        }

        // Get all users
        $stmt = $conn->prepare("SELECT id, name, phone, is_admin FROM users ORDER BY name");
        if (!$stmt) {
            error_log("Prepare failed for users query: " . $conn->error);
            response(['success' => false, 'message' => 'Database error: ' . $conn->error]);
            exit;
        }

        if (!$stmt->execute()) {
            error_log("Execute failed for users query: " . $stmt->error);
            response(['success' => false, 'message' => 'Failed to execute query: ' . $stmt->error]);
            exit;
        }

        $result = $stmt->get_result();
        if (!$result) {
            error_log("Failed to get result for users query");
            response(['success' => false, 'message' => 'Failed to get result']);
            exit;
        }
       
        $users = [];
        while ($row = $result->fetch_assoc()) {
            $users[] = [
                'id' => $row['id'],
                'name' => $row['name'],
                'phone' => $row['phone'],
                'is_admin' => (int)$row['is_admin']
            ];
        }
        
        error_log("Found " . count($users) . " users");
        error_log("Users data: " . print_r($users, true));
        
        response([
            'success' => true,
            'users' => $users
        ]);
    } catch (Exception $e) {
        error_log("Exception in get_users: " . $e->getMessage());
        response([
            'success' => false,
            'message' => 'Error: ' . $e->getMessage()
        ]);
    }
}

elseif ($action === 'delete_user') {
    $user_id = $_POST['user_id'] ?? '';
    
    if (empty($user_id)) {
        response(['success' => false, 'message' => 'User ID is required']);
        exit;
    }
    
    // First check if user exists and is not an admin
    $stmt = $conn->prepare("SELECT is_admin FROM users WHERE id = ?");
    $stmt->bind_param("i", $user_id);
    $stmt->execute();
    $result = $stmt->get_result();
    
    if ($result->num_rows === 0) {
        response(['success' => false, 'message' => 'User not found']);
        exit;
    }
    
    $user = $result->fetch_assoc();
    if ($user['is_admin'] == 1) {
        response(['success' => false, 'message' => 'Cannot delete admin users']);
        exit;
    }
    
    // Delete user's products first
    $stmt = $conn->prepare("DELETE FROM products WHERE user_id = ?");
    $stmt->bind_param("i", $user_id);
    $stmt->execute();
    
    // Then delete the user
    $stmt = $conn->prepare("DELETE FROM users WHERE id = ?");
    $stmt->bind_param("i", $user_id);
    
    if ($stmt->execute()) {
        response(['success' => true, 'message' => 'User deleted successfully']);
    } else {
        response(['success' => false, 'message' => 'Failed to delete user']);
    }
}

elseif ($action === 'add_category') {
    $name = $_POST['name'] ?? '';
    
    if (empty($name)) {
        response(['success' => false, 'message' => 'Category name is required']);
        exit;
    }
    
    // Check if category already exists
    $stmt = $conn->prepare("SELECT id FROM categories WHERE name = ?");
    $stmt->bind_param("s", $name);
    $stmt->execute();
    $result = $stmt->get_result();
    
    if ($result->num_rows > 0) {
        response(['success' => false, 'message' => 'Category already exists']);
        exit;
    }
    
    // Add new category
    $stmt = $conn->prepare("INSERT INTO categories (name) VALUES (?)");
    $stmt->bind_param("s", $name);
    
    if ($stmt->execute()) {
        response([
            'success' => true,
            'message' => 'Category added successfully',
            'category_id' => $conn->insert_id
        ]);
    } else {
        response(['success' => false, 'message' => 'Failed to add category']);
    }
}

elseif ($action === 'delete_category') {
    $category_id = $_POST['category_id'] ?? '';
    
    if (empty($category_id)) {
        response(['success' => false, 'message' => 'Category ID is required']);
        exit;
    }
    
    // Check if category exists
    $stmt = $conn->prepare("SELECT id FROM categories WHERE id = ?");
    $stmt->bind_param("i", $category_id);
    $stmt->execute();
    $result = $stmt->get_result();
    
    if ($result->num_rows === 0) {
        response(['success' => false, 'message' => 'Category not found']);
        exit;
    }
    
    // Check if category is in use
    $stmt = $conn->prepare("SELECT id FROM products WHERE category = (SELECT name FROM categories WHERE id = ?)");
    $stmt->bind_param("i", $category_id);
    $stmt->execute();
    $result = $stmt->get_result();
    
    if ($result->num_rows > 0) {
        response(['success' => false, 'message' => 'Cannot delete category that is in use by products']);
        exit;
    }
    
    // Delete category
    $stmt = $conn->prepare("DELETE FROM categories WHERE id = ?");
    $stmt->bind_param("i", $category_id);
    
    if ($stmt->execute()) {
        response(['success' => true, 'message' => 'Category deleted successfully']);
    } else {
        response(['success' => false, 'message' => 'Failed to delete category']);
    }
}

elseif ($action === 'get_categories') {
    try {
        error_log("get_categories action started");
        
        $stmt = $conn->prepare("SELECT id, name FROM categories ORDER BY name");
        if (!$stmt) {
            error_log("Prepare failed for categories query: " . $conn->error);
            response(['success' => false, 'message' => 'Database error: ' . $conn->error]);
            exit;
        }

        if (!$stmt->execute()) {
            error_log("Execute failed for categories query: " . $stmt->error);
            response(['success' => false, 'message' => 'Failed to execute query: ' . $stmt->error]);
            exit;
        }

        $result = $stmt->get_result();
        if (!$result) {
            error_log("Failed to get result for categories query");
            response(['success' => false, 'message' => 'Failed to get result']);
            exit;
        }
       
        $categories = [];
        while ($row = $result->fetch_assoc()) {
            $categories[] = [
                'id' => $row['id'],
                'name' => $row['name']
            ];
        }
        
        error_log("Found " . count($categories) . " categories");
        error_log("Categories data: " . print_r($categories, true));
        
        response([
            'success' => true,
            'categories' => $categories
        ]);
    } catch (Exception $e) {
        error_log("Exception in get_categories: " . $e->getMessage());
        response([
            'success' => false,
            'message' => 'Error: ' . $e->getMessage()
        ]);
    }
}

elseif ($action === 'get_stats') {
    try {
        error_log("get_stats action started");
        
        // Get total users count
        $stmt = $conn->prepare("SELECT COUNT(*) as count FROM users");
        $stmt->execute();
        $result = $stmt->get_result();
        $total_users = $result->fetch_assoc()['count'];

        // Get total products count
        $stmt = $conn->prepare("SELECT COUNT(*) as count FROM products");
        $stmt->execute();
        $result = $stmt->get_result();
        $total_products = $result->fetch_assoc()['count'];

        // Get total categories count
        $stmt = $conn->prepare("SELECT COUNT(*) as count FROM categories");
        $stmt->execute();
        $result = $stmt->get_result();
        $total_categories = $result->fetch_assoc()['count'];

        // Get active sellers count (users who have listed products)
        $stmt = $conn->prepare("SELECT COUNT(DISTINCT user_id) as count FROM products");
        $stmt->execute();
        $result = $stmt->get_result();
        $active_sellers = $result->fetch_assoc()['count'];

        // Get recent products
        $stmt = $conn->prepare("
            SELECT 
                p.id,
                p.title as name,
                p.price,
                p.created_at,
                u.name as seller_name
            FROM products p
            JOIN users u ON p.user_id = u.id
            ORDER BY p.created_at DESC
            LIMIT 5
        ");
        $stmt->execute();
        $result = $stmt->get_result();
        
        $recent_products = [];
        while ($row = $result->fetch_assoc()) {
            $recent_products[] = [
                'id' => $row['id'],
                'name' => $row['name'],
                'price' => $row['price'],
                'created_at' => $row['created_at'],
                'seller_name' => $row['seller_name']
            ];
        }

        // Get category distribution
        $stmt = $conn->prepare("
            SELECT 
                category,
                COUNT(*) as count
            FROM products
            GROUP BY category
            ORDER BY count DESC
        ");
        $stmt->execute();
        $result = $stmt->get_result();
        
        $category_distribution = [];
        while ($row = $result->fetch_assoc()) {
            $category_distribution[] = [
                'category' => $row['category'],
                'count' => $row['count']
            ];
        }

        // Get price statistics
        $stmt = $conn->prepare("
            SELECT 
                MIN(price) as min_price,
                MAX(price) as max_price,
                AVG(price) as avg_price
            FROM products
        ");
        $stmt->execute();
        $result = $stmt->get_result();
        $price_stats = $result->fetch_assoc();

        response([
            'success' => true,
            'stats' => [
                'total_users' => (int)$total_users,
                'total_products' => (int)$total_products,
                'total_categories' => (int)$total_categories,
                'active_sellers' => (int)$active_sellers,
                'recent_products' => $recent_products,
                'category_distribution' => $category_distribution,
                'price_stats' => [
                    'min_price' => (float)$price_stats['min_price'],
                    'max_price' => (float)$price_stats['max_price'],
                    'avg_price' => (float)$price_stats['avg_price']
                ]
            ]
        ]);
    } catch (Exception $e) {
        error_log("Exception in get_stats: " . $e->getMessage());
        response([
            'success' => false,
            'message' => 'Error: ' . $e->getMessage()
        ]);
    }
}

?> 