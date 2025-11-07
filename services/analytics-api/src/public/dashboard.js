// ============================================================================
// Analytics Dashboard - Auto-refresh functionality
// ============================================================================

// Connect to Socket.io
const socket = io();

// Track orders and state
let orders = [];
let users = new Set();
let lastUpdate = null;
let autoRefreshInterval = null;

// ============================================================================
// Update Functions
// ============================================================================

/**
 * Update timestamp display
 */
function updateTimestamp() {
    const timestampElement = document.getElementById('last-update-time');
    if (lastUpdate) {
        const time = lastUpdate.toLocaleTimeString('en-US', {
            hour: '2-digit',
            minute: '2-digit',
            second: '2-digit'
        });
        timestampElement.textContent = time;
    }
}

/**
 * Update stats display
 */
function updateStats() {
    document.getElementById('total-orders').textContent = orders.length;
    
    const revenue = orders.reduce((sum, order) => sum + (parseFloat(order.amount) || 0), 0);
    document.getElementById('total-revenue').textContent = `$${revenue.toFixed(2)}`;
    
    const avgOrder = orders.length > 0 ? revenue / orders.length : 0;
    document.getElementById('avg-order').textContent = `$${avgOrder.toFixed(2)}`;
    
    document.getElementById('active-users').textContent = users.size;
}

/**
 * Update orders table
 */
function updateOrdersTable() {
    const tbody = document.getElementById('orders-body');
    
    if (orders.length === 0) {
        tbody.innerHTML = '<tr><td colspan="5" class="no-data">No orders received yet</td></tr>';
        return;
    }
    
    tbody.innerHTML = '';
    
    // Sort orders by timestamp (newest first)
    const sortedOrders = [...orders].sort((a, b) => {
        const dateA = new Date(a.createdAt || 0);
        const dateB = new Date(b.createdAt || 0);
        return dateB.getTime() - dateA.getTime();
    });
    
    // Show only the 10 most recent orders
    const recentOrders = sortedOrders.slice(0, 10);
    
    recentOrders.forEach(order => {
        const tr = document.createElement('tr');
        
        // Format timestamp
        let formattedDate = 'N/A';
        try {
            const date = new Date(order.createdAt);
            formattedDate = date.toLocaleString();
        } catch (e) {
            console.error('Error parsing date:', e, order.createdAt);
        }
        
        // Determine status class
        let statusClass = 'status-pending';
        if (order.status === 'COMPLETED') {
            statusClass = 'status-completed';
        } else if (order.status === 'FAILED') {
            statusClass = 'status-failed';
        }
        
        tr.innerHTML = `
            <td>${escapeHtml(order.orderId)}</td>
            <td>${escapeHtml(order.userId || 'N/A')}</td>
            <td>$${(parseFloat(order.amount) || 0).toFixed(2)}</td>
            <td><span class="status ${statusClass}">${escapeHtml(order.status)}</span></td>
            <td>${formattedDate}</td>
        `;
        
        tbody.appendChild(tr);
    });
}

/**
 * Escape HTML to prevent XSS
 */
function escapeHtml(text) {
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
}

// ============================================================================
// Data Refresh Logic
// ============================================================================

/**
 * Refresh data from API
 */
async function refreshData() {
    try {
        console.log('Refreshing data...');
        const response = await fetch('/api/messages/recent');
        
        if (!response.ok) {
            throw new Error(`HTTP error! Status: ${response.status}`);
        }
        
        const data = await response.json();
        console.log('Received data:', data);
        
        if (data.messages && data.messages.length > 0) {
            orders = data.messages;
            users = new Set();
            orders.forEach(order => {
                if (order.userId) {
                    users.add(order.userId);
                }
            });
        }
        
        lastUpdate = new Date();
        updateStats();
        updateOrdersTable();
        updateTimestamp();
        
        // Hide error banner on successful refresh
        document.getElementById('error-container').style.display = 'none';
        
        console.log('Data refresh successful');
    } catch (error) {
        console.error('Error fetching messages:', error);
        document.getElementById('error-message').textContent = `Error: ${error.message}`;
        document.getElementById('error-container').style.display = 'block';
    }
}

/**
 * Start auto-refresh (every 2 seconds)
 */
function startAutoRefresh() {
    const AUTO_REFRESH_INTERVAL = 2000; // 2 seconds
    
    if (autoRefreshInterval) {
        clearInterval(autoRefreshInterval);
    }
    
    autoRefreshInterval = setInterval(refreshData, AUTO_REFRESH_INTERVAL);
    console.log('Auto-refresh started (every 2 seconds)');
}

/**
 * Stop auto-refresh
 */
function stopAutoRefresh() {
    if (autoRefreshInterval) {
        clearInterval(autoRefreshInterval);
        autoRefreshInterval = null;
        console.log('Auto-refresh stopped');
    }
}

// ============================================================================
// Socket.io Real-time Updates
// ============================================================================

/**
 * Listen for new orders via Socket.io (real-time updates)
 */
socket.on('new-order', (order) => {
    console.log('Received new order via Socket.io:', order.orderId);
    orders.push(order);
    if (order.userId) {
        users.add(order.userId);
    }
    lastUpdate = new Date();
    updateStats();
    updateOrdersTable();
    updateTimestamp();
});

/**
 * Listen for order status updates via Socket.io
 */
socket.on('order-update', (updatedOrder) => {
    console.log('Received order update via Socket.io:', updatedOrder.orderId);
    const index = orders.findIndex(order => order.orderId === updatedOrder.orderId);
    if (index !== -1) {
        orders[index] = updatedOrder;
        lastUpdate = new Date();
        updateStats();
        updateOrdersTable();
        updateTimestamp();
    }
});

// ============================================================================
// Initialization
// ============================================================================

/**
 * Initialize dashboard
 */
async function initializeDashboard() {
    console.log('=== Analytics Dashboard Initializing ===');
    
    // Perform initial data load
    await refreshData();
    
    // Start auto-refresh
    startAutoRefresh();
    
    console.log('=== Dashboard Initialization Complete ===');
}

// Initialize when DOM is ready
if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', initializeDashboard);
} else {
    initializeDashboard();
}

// Clean up on page unload
window.addEventListener('beforeunload', () => {
    stopAutoRefresh();
});
