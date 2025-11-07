// ============================================================================
// API Client Module
// ============================================================================

const API = {
    baseURL: window.location.origin,
    
    /**
     * Fetch inventory items with optional source filter
     * @param {string|null} source - Filter by source ('json', 'avro', or null for all)
     * @returns {Promise<Array>} Array of inventory items
     */
    async fetchInventory(source = null) {
        try {
            const url = source ? `${this.baseURL}/inventory?source=${source}` : `${this.baseURL}/inventory`;
            const response = await fetch(url);
            
            if (!response.ok) {
                const errorMsg = `Failed to fetch inventory: HTTP ${response.status} ${response.statusText}`;
                console.error(errorMsg);
                throw new Error(errorMsg);
            }
            
            const data = await response.json();
            console.log(`Successfully fetched ${data.length} inventory items`);
            return data;
        } catch (error) {
            // Log detailed error information for debugging (Requirement 7.4)
            if (error.name === 'TypeError' && error.message.includes('fetch')) {
                console.error('Network error: Unable to reach Inventory Service API', error);
            } else {
                console.error('Failed to fetch inventory:', error.message, error);
            }
            throw error;
        }
    },
    
    /**
     * Fetch health status of consumers
     * @returns {Promise<Object>} Health status object
     */
    async fetchHealth() {
        try {
            const response = await fetch(`${this.baseURL}/health`);
            
            if (!response.ok) {
                const errorMsg = `Failed to fetch health status: HTTP ${response.status} ${response.statusText}`;
                console.error(errorMsg);
                throw new Error(errorMsg);
            }
            
            const data = await response.json();
            console.log('Successfully fetched health status:', data);
            return data;
        } catch (error) {
            // Log detailed error information for debugging (Requirement 7.4)
            if (error.name === 'TypeError' && error.message.includes('fetch')) {
                console.error('Network error: Unable to reach health endpoint', error);
            } else {
                console.error('Failed to fetch health status:', error.message, error);
            }
            throw error;
        }
    },
    
    /**
     * Fetch error statistics from consumers
     * @returns {Promise<Object>} Error statistics object
     */
    async fetchErrors() {
        try {
            const response = await fetch(`${this.baseURL}/errors`);
            
            if (!response.ok) {
                const errorMsg = `Failed to fetch error statistics: HTTP ${response.status} ${response.statusText}`;
                console.error(errorMsg);
                throw new Error(errorMsg);
            }
            
            const data = await response.json();
            console.log('Successfully fetched error statistics');
            return data;
        } catch (error) {
            // Log detailed error information for debugging (Requirement 7.4)
            if (error.name === 'TypeError' && error.message.includes('fetch')) {
                console.error('Network error: Unable to reach errors endpoint', error);
            } else {
                console.error('Failed to fetch error statistics:', error.message, error);
            }
            throw error;
        }
    }
};

// ============================================================================
// State Management
// ============================================================================

const state = {
    inventory: [],
    health: null,
    errors: null,
    activeFilter: 'all',
    lastUpdate: null,
    isLoading: true,
    connectionError: false
};

/**
 * Update state and trigger re-render
 * @param {Object} updates - Partial state updates
 */
function updateState(updates) {
    Object.assign(state, updates);
    render();
}

/**
 * Set the active filter and refresh data
 * @param {string} filter - Filter value ('all', 'json', 'avro')
 * Requirements: 2.1, 2.2, 2.3
 */
function setActiveFilter(filter) {
    // Update active filter state
    state.activeFilter = filter;
    
    // Apply active styling to selected filter button
    document.querySelectorAll('.filter-btn').forEach(btn => {
        btn.classList.remove('active');
    });
    document.querySelector(`[data-filter="${filter}"]`).classList.add('active');
    
    // Trigger data refresh with selected filter
    refreshData();
}

/**
 * Get filtered inventory items based on active filter
 * @returns {Array} Filtered inventory items
 * Requirements: 2.1, 2.4, 2.5
 */
function getFilteredInventory() {
    // Filter inventory items based on selected source
    if (state.activeFilter === 'all') {
        return state.inventory;
    }
    return state.inventory.filter(item => item.source === state.activeFilter);
}

// ============================================================================
// DOM Rendering Functions
// ============================================================================

/**
 * Render inventory table with current data
 * Requirements: 1.1, 1.2, 1.4, 1.5, 2.4
 */
function renderInventoryTable() {
    const tbody = document.getElementById('inventory-tbody');
    const emptyState = document.getElementById('empty-state');
    const itemCountSpan = document.getElementById('item-count');
    
    // Get filtered inventory based on active filter
    const filteredItems = getFilteredInventory();
    
    // Update item count to reflect filtered results (Requirement 2.4)
    itemCountSpan.textContent = filteredItems.length;
    
    // Show empty state if no items
    if (filteredItems.length === 0) {
        tbody.innerHTML = '';
        emptyState.style.display = 'block';
        return;
    }
    
    // Hide empty state and render table rows
    emptyState.style.display = 'none';
    
    // Generate table rows
    tbody.innerHTML = filteredItems.map(item => {
        const sourceClass = `source-${item.source}`;
        return `
            <tr class="${sourceClass}">
                <td>${escapeHtml(item.order_id)}</td>
                <td>${escapeHtml(item.product_id)}</td>
                <td>${item.quantity}</td>
                <td>${escapeHtml(item.user_id)}</td>
                <td>${escapeHtml(item.status)}</td>
                <td><span class="source-badge">${escapeHtml(item.source)}</span></td>
            </tr>
        `;
    }).join('');
}

/**
 * Escape HTML to prevent XSS
 * @param {string} text - Text to escape
 * @returns {string} Escaped text
 */
function escapeHtml(text) {
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
}

/**
 * Render health status section with consumer status
 * Requirements: 3.1, 3.2, 3.3, 3.5
 */
function renderHealthStatus() {
    if (!state.health) {
        return;
    }
    
    // JSON Consumer status
    const jsonStatusBadge = document.getElementById('json-status-badge');
    const jsonErrorCount = document.getElementById('json-error-count');
    
    // Avro Consumer status
    const avroStatusBadge = document.getElementById('avro-status-badge');
    const avroErrorCount = document.getElementById('avro-error-count');
    
    // Update JSON consumer status
    const jsonStatus = state.health.kafka || 'disconnected';
    jsonStatusBadge.textContent = jsonStatus === 'connected' ? 'Connected' : 'Disconnected';
    jsonStatusBadge.className = `status-badge ${jsonStatus}`;
    
    // Update Avro consumer status
    const avroStatus = state.health.avro_kafka || 'disconnected';
    avroStatusBadge.textContent = avroStatus === 'connected' ? 'Connected' : 'Disconnected';
    avroStatusBadge.className = `status-badge ${avroStatus}`;
    
    // Update error counts
    if (state.health.error_count) {
        jsonErrorCount.textContent = state.health.error_count.json || 0;
        avroErrorCount.textContent = state.health.error_count.avro || 0;
    }
    
    // Update last refresh timestamp
    updateTimestamp();
}

/**
 * Update the last update timestamp
 * Requirements: 3.5
 */
function updateTimestamp() {
    const timestampElement = document.getElementById('last-update-time');
    
    if (state.lastUpdate) {
        const time = state.lastUpdate.toLocaleTimeString('en-US', {
            hour: '2-digit',
            minute: '2-digit',
            second: '2-digit'
        });
        timestampElement.textContent = time;
    }
}

/**
 * Render errors section with error messages from both consumers
 * Requirements: 4.1, 4.2, 4.3, 4.4, 4.5
 */
function renderErrorsSection() {
    if (!state.errors) {
        return;
    }
    
    // Update total error count
    const totalErrorCount = document.getElementById('total-error-count');
    const jsonErrorCount = state.errors.json_consumer?.error_count || 0;
    const avroErrorCount = state.errors.avro_consumer?.error_count || 0;
    const totalErrors = jsonErrorCount + avroErrorCount;
    totalErrorCount.textContent = totalErrors;
    
    // Render JSON consumer errors
    const jsonErrorsList = document.getElementById('json-errors-list');
    renderErrorList(jsonErrorsList, state.errors.json_consumer?.last_errors || []);
    
    // Render Avro consumer errors
    const avroErrorsList = document.getElementById('avro-errors-list');
    renderErrorList(avroErrorsList, state.errors.avro_consumer?.last_errors || []);
}

/**
 * Render error list for a specific consumer
 * @param {HTMLElement} listElement - The UL element to render errors into
 * @param {Array<string>} errors - Array of error messages (max 10)
 * Requirements: 4.2, 4.3, 4.4
 */
function renderErrorList(listElement, errors) {
    if (!errors || errors.length === 0) {
        listElement.innerHTML = '<li class="no-errors">No errors</li>';
        return;
    }
    
    // Display up to 10 most recent errors
    const recentErrors = errors.slice(0, 10);
    listElement.innerHTML = recentErrors.map(error => 
        `<li>${escapeHtml(error)}</li>`
    ).join('');
}

/**
 * Initialize expand/collapse functionality for errors section
 * Requirements: 4.5
 */
function initializeErrorsToggle() {
    const toggleButton = document.getElementById('toggle-errors');
    const errorsContent = document.getElementById('errors-content');
    const errorsHeader = document.querySelector('.errors-header');
    
    let isExpanded = false;
    
    const toggleErrors = () => {
        isExpanded = !isExpanded;
        
        if (isExpanded) {
            errorsContent.style.display = 'block';
            toggleButton.textContent = '▲ Collapse';
        } else {
            errorsContent.style.display = 'none';
            toggleButton.textContent = '▼ Expand';
        }
    };
    
    // Add click handlers
    toggleButton.addEventListener('click', (e) => {
        e.stopPropagation();
        toggleErrors();
    });
    
    errorsHeader.addEventListener('click', toggleErrors);
}

// ============================================================================
// Main Render Function
// ============================================================================

/**
 * Main render function - updates all UI sections based on current state
 * Requirements: 7.1, 7.3, 7.5
 */
function render() {
    // Hide loading spinner once we have data (Requirement 7.5)
    if (!state.isLoading) {
        document.getElementById('loading-spinner').style.display = 'none';
        document.getElementById('health-section').style.display = 'block';
        document.getElementById('filter-section').style.display = 'block';
        document.getElementById('inventory-section').style.display = 'block';
        document.getElementById('errors-section').style.display = 'block';
    }
    
    // Show/hide connection error banner (Requirement 7.1)
    const connectionError = document.getElementById('connection-error');
    if (state.connectionError) {
        connectionError.style.display = 'block';
        console.log('Connection error banner displayed');
    } else {
        connectionError.style.display = 'none';
    }
    
    // Render all sections with last successful data (Requirement 7.3)
    renderInventoryTable();
    renderHealthStatus();
    renderErrorsSection();
}

// ============================================================================
// Data Refresh Logic
// ============================================================================

/**
 * Refresh all data from the API
 * Fetches inventory, health, and errors concurrently using Promise.all
 * Requirements: 1.3, 3.4, 7.1, 7.2, 7.3
 */
async function refreshData() {
    try {
        // Fetch all data concurrently using Promise.all for better performance
        // Note: We fetch ALL inventory data and filter client-side to maintain filter state
        const filterParam = state.activeFilter !== 'all' ? state.activeFilter : null;
        
        console.log(`Refreshing data (filter: ${state.activeFilter})...`);
        
        const [inventory, health, errors] = await Promise.all([
            API.fetchInventory(filterParam),
            API.fetchHealth(),
            API.fetchErrors()
        ]);
        
        // Update state with all fetched data
        state.inventory = inventory;
        state.health = health;
        state.errors = errors;
        state.lastUpdate = new Date();
        state.connectionError = false;
        state.isLoading = false;
        
        console.log('Data refresh successful');
        
        // Re-render the UI with updated data
        render();
    } catch (error) {
        // Handle connection errors gracefully without stopping refresh cycle (Requirement 7.2)
        console.error('Failed to refresh data:', error.message);
        console.log('Retrying on next refresh cycle...');
        
        // Set connection error flag to display banner (Requirement 7.1)
        state.connectionError = true;
        state.isLoading = false;
        
        // Display last successfully fetched data when new requests fail (Requirement 7.3)
        // UI remains responsive during failed API calls (Requirement 7.5)
        render();
    }
}

/**
 * Auto-refresh interval ID for cleanup
 */
let autoRefreshInterval = null;

/**
 * Start auto-refresh mechanism
 * Calls refreshData() every 2 seconds
 * Requirements: 1.3, 3.4, 7.2
 */
function startAutoRefresh() {
    const AUTO_REFRESH_INTERVAL = 2000; // 2 seconds
    
    // Clear any existing interval
    if (autoRefreshInterval) {
        clearInterval(autoRefreshInterval);
    }
    
    // Set up interval timer to call refresh function every 2 seconds
    autoRefreshInterval = setInterval(refreshData, AUTO_REFRESH_INTERVAL);
    
    console.log('Auto-refresh started (every 2 seconds)');
}

/**
 * Stop auto-refresh mechanism (for cleanup)
 */
function stopAutoRefresh() {
    if (autoRefreshInterval) {
        clearInterval(autoRefreshInterval);
        autoRefreshInterval = null;
        console.log('Auto-refresh stopped');
    }
}

// ============================================================================
// Initialization
// ============================================================================

/**
 * Initialize the dashboard on page load
 * Requirements: 7.1, 7.2, 7.4
 */
async function initializeDashboard() {
    console.log('=== Inventory Service Dashboard Initializing ===');
    console.log('API Base URL:', API.baseURL);
    console.log('Initial state:', state);
    
    // Initialize errors section toggle functionality
    initializeErrorsToggle();
    
    // Set up filter button event listeners
    // Requirements: 2.1, 2.2, 2.3
    document.querySelectorAll('.filter-btn').forEach(btn => {
        btn.addEventListener('click', () => {
            const filter = btn.getAttribute('data-filter');
            setActiveFilter(filter);
        });
    });
    
    console.log('Event listeners attached');
    
    // Perform initial data load (Requirement 7.4)
    console.log('Performing initial data load...');
    try {
        await refreshData();
        console.log('Initial data load complete');
    } catch (error) {
        console.error('Initial data load failed:', error.message);
        console.log('Will retry automatically...');
    }
    
    // Start auto-refresh mechanism (every 2 seconds)
    // Requirements: 1.3, 3.4, 7.2
    startAutoRefresh();
    
    console.log('=== Dashboard Initialization Complete ===');
}

// Initialize when DOM is ready
if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', initializeDashboard);
} else {
    initializeDashboard();
}

// Clean up auto-refresh on page unload
window.addEventListener('beforeunload', () => {
    stopAutoRefresh();
});
