import { applyImageFallback } from "../../utils/fallbackImage";

export default function AdminSectionContent({ vm }) {
  const {
    section,
    editingId,
    form,
    setForm,
    handleProductImageChange,
    handleProductImageUrlChange,
    saveProduct,
    resetForm,
    editingPromoId,
    promoForm,
    setPromoForm,
    createPromo,
    resetPromoForm,
    promos,
    startEditPromo,
    editingHeroOfferId,
    heroOfferForm,
    setHeroOfferForm,
    createHeroOffer,
    resetHeroOfferForm,
    heroOffers,
    startEditHeroOffer,
    removeHeroOffer,
    products,
    flashSaleProductIds,
    startEdit,
    toggleProductFlashSale,
    removeProduct,
    pendingReturnOrders,
    setSection,
    setSelectedOrderId,
    orderFilters,
    setOrderFilters,
    filteredOrders,
    selectedOrder,
    updateOrderStatus,
    returnReviewNote,
    setReturnReviewNote,
    reviewReturnRequest,
    returnTrackingStatus,
    setReturnTrackingStatus,
    updateReturnTracking,
    handleTrackOrder,
    handleRefundOrder,
    customers,
    selectedCustomer,
    setSelectedCustomerEmail,
    serviceFilters,
    setServiceFilters,
    filteredServiceRequests,
    selectedServiceRequest,
    setSelectedServiceRequestId,
    serviceTrackingStatus,
    setServiceTrackingStatus,
    serviceAdminNote,
    setServiceAdminNote,
    updateServiceStatus,
    inventoryInsights,
    productPerformance,
    saveFlashSaleProducts,
    toggleFlashSaleProduct,
    editingFeaturedSectionId,
    featuredSectionForm,
    setFeaturedSectionForm,
    createFeaturedSection,
    resetFeaturedSectionForm,
    featuredSections,
    startEditFeaturedSection,
    removeFeaturedSection
  } = vm;

  return (
    <>
        {section === "products" && (
        <section className="admin-form-wrap">
          <h2>{editingId ? "Edit Product" : "Add Product"}</h2>
          <div className="admin-form-grid">
            <input
              placeholder="Product name"
              value={form.name}
              onChange={(e) => setForm((prev) => ({ ...prev, name: e.target.value }))}
            />
            <input
              type="number"
              min="0"
              placeholder="Price"
              value={form.price}
              onChange={(e) => setForm((prev) => ({ ...prev, price: e.target.value }))}
            />
            <input
              placeholder="Tag"
              value={form.tag}
              onChange={(e) => setForm((prev) => ({ ...prev, tag: e.target.value }))}
            />
            <input
              placeholder="Brand"
              value={form.brand}
              onChange={(e) => setForm((prev) => ({ ...prev, brand: e.target.value }))}
            />
            <input
              placeholder="Colour Family"
              value={form.colorFamily}
              onChange={(e) =>
                setForm((prev) => ({ ...prev, colorFamily: e.target.value }))
              }
            />
            <input
              type="url"
              placeholder="Image URL (optional, e.g. https://...)"
              value={form.image}
              onChange={handleProductImageUrlChange}
            />
            <input
  placeholder="Paste product URL"
  value={productUrl}
  onChange={(e) => setProductUrl(e.target.value)}
/>

<button onClick={fetchProductFromUrl}>
  Fetch Product
</button>
            <input
              type="number"
              min="0"
              placeholder="Stock"
              value={form.stock}
              onChange={(e) => setForm((prev) => ({ ...prev, stock: e.target.value }))}
            />
            <input type="file" accept="image/*" onChange={handleProductImageChange} />
          </div>
          {form.image && (
            <div className="admin-image-preview-wrap">
              <img
                src={form.image}
                alt="Product preview"
                className="admin-image-preview"
                onError={applyImageFallback}
              />
              <button
                className="admin-secondary-btn"
                onClick={() => setForm((prev) => ({ ...prev, image: "" }))}
              >
                Remove Image
              </button>
            </div>
          )}

          <div className="admin-actions">
            <button onClick={saveProduct} className="admin-primary-btn">
              {editingId ? "Update Product" : "Add Product"}
            </button>
            {editingId && (
              <button onClick={resetForm} className="admin-secondary-btn">
                Cancel Edit
              </button>
            )}
          </div>
        </section>
        )}
        {section === "promos" && (
        <section className="admin-form-wrap">
          <h2>{editingPromoId ? "Edit Payment Promo Code" : "Create Payment Promo Code"}</h2>
          <div className="admin-form-grid">
            <input
              placeholder="Promo Code (e.g. SAVE20)"
              value={promoForm.code}
              onChange={(e) =>
                setPromoForm((prev) => ({ ...prev, code: e.target.value.toUpperCase() }))
              }
            />
            <select
              value={promoForm.discountType}
              onChange={(e) =>
                setPromoForm((prev) => ({ ...prev, discountType: e.target.value }))
              }
            >
              <option value="percent">Percent</option>
              <option value="flat">Flat Amount</option>
              <option value="shipping">Free Shipping</option>
            </select>
            <input
              type="number"
              min="0"
              placeholder="Value (%) / Amount ($)"
              value={promoForm.discountValue}
              onChange={(e) =>
                setPromoForm((prev) => ({ ...prev, discountValue: e.target.value }))
              }
            />
            <input
              type="number"
              min="1"
              placeholder="Usage Limit (max redemptions)"
              value={promoForm.maxUses}
              onChange={(e) => setPromoForm((prev) => ({ ...prev, maxUses: e.target.value }))}
            />
            <input
              type="datetime-local"
              aria-label="Starts On"
              value={promoForm.startsAt}
              onChange={(e) => setPromoForm((prev) => ({ ...prev, startsAt: e.target.value }))}
            />
            <input
              type="datetime-local"
              aria-label="Ends On"
              value={promoForm.endsAt}
              onChange={(e) => setPromoForm((prev) => ({ ...prev, endsAt: e.target.value }))}
            />
            <select
              value={promoForm.isActive ? "active" : "inactive"}
              onChange={(e) =>
                setPromoForm((prev) => ({ ...prev, isActive: e.target.value === "active" }))
              }
            >
              <option value="active">Active</option>
              <option value="inactive">Inactive</option>
            </select>
          </div>
          <div className="admin-actions">
            <button onClick={createPromo} className="admin-primary-btn">
              {editingPromoId ? "Update Promo Code" : "Add Promo Code"}
            </button>
            {editingPromoId && (
              <button onClick={resetPromoForm} className="admin-secondary-btn">
                Cancel Edit
              </button>
            )}
          </div>
        </section>
        )}
        {section === "promos" && (
        <section className="admin-table-wrap">
          <h2>Payment Promo Codes</h2>
          <table className="admin-table">
            <thead>
              <tr>
                <th>Code</th>
                <th>Discount Type</th>
                <th>Value (% / $)</th>
                <th>Used / Limit</th>
                <th>Starts On</th>
                <th>Ends On</th>
                <th>Status</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              {promos.map((promo) => (
                <tr key={promo._id}>
                  <td>{promo.code}</td>
                  <td>{promo.discountType}</td>
                  <td>{promo.discountValue}</td>
                  <td>
                    {promo.usedCount}/{promo.maxUses}
                  </td>
                  <td>{new Date(promo.startsAt).toLocaleString()}</td>
                  <td>{new Date(promo.endsAt).toLocaleString()}</td>
                  <td>{promo.status}</td>
                  <td>
                    <button
                      className="table-edit-btn"
                      onClick={() => startEditPromo(promo)}
                    >
                      Edit
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </section>
        )}
        {section === "promos" && (
        <section className="admin-form-wrap">
          <h2>{editingHeroOfferId ? "Edit Hero Offer Banner" : "Create Hero Offer Banner"}</h2>
          <p className="admin-hint">
            Set <strong>Type = Flash Offer</strong> to power the Flash Sale countdown in shop hero.
          </p>
          <div className="admin-form-grid">
            <input
              placeholder="Offer text (e.g. 🔥 60% OFF Electronics)"
              value={heroOfferForm.title}
              onChange={(e) =>
                setHeroOfferForm((prev) => ({ ...prev, title: e.target.value }))
              }
            />
            <select
              value={heroOfferForm.offerType}
              onChange={(e) =>
                setHeroOfferForm((prev) => ({ ...prev, offerType: e.target.value }))
              }
            >
              <option value="tag">Tag Offer</option>
              <option value="flash">Flash Offer</option>
            </select>
            <input
              type="number"
              min="0"
              placeholder="Priority"
              value={heroOfferForm.priority}
              onChange={(e) =>
                setHeroOfferForm((prev) => ({ ...prev, priority: e.target.value }))
              }
            />
            <input
              placeholder="CTA search query (optional)"
              value={heroOfferForm.ctaQuery}
              onChange={(e) =>
                setHeroOfferForm((prev) => ({ ...prev, ctaQuery: e.target.value }))
              }
            />
            <input
              type="datetime-local"
              aria-label="Offer Starts On"
              value={heroOfferForm.startsAt}
              onChange={(e) =>
                setHeroOfferForm((prev) => ({ ...prev, startsAt: e.target.value }))
              }
            />
            <input
              type="datetime-local"
              aria-label="Offer Ends On"
              value={heroOfferForm.endsAt}
              onChange={(e) =>
                setHeroOfferForm((prev) => ({ ...prev, endsAt: e.target.value }))
              }
            />
            <select
              value={heroOfferForm.isActive ? "active" : "inactive"}
              onChange={(e) =>
                setHeroOfferForm((prev) => ({
                  ...prev,
                  isActive: e.target.value === "active"
                }))
              }
            >
              <option value="active">Active</option>
              <option value="inactive">Inactive</option>
            </select>
          </div>
          <div className="admin-actions">
            <button onClick={createHeroOffer} className="admin-primary-btn">
              {editingHeroOfferId ? "Update Hero Offer" : "Add Hero Offer"}
            </button>
            {editingHeroOfferId && (
              <button onClick={resetHeroOfferForm} className="admin-secondary-btn">
                Cancel Edit
              </button>
            )}
          </div>
        </section>
        )}
        {section === "promos" && (
        <section className="admin-table-wrap">
          <h2>Hero Offers (Shop Banner)</h2>
          <table className="admin-table">
            <thead>
              <tr>
                <th>Text</th>
                <th>Type</th>
                <th>Priority</th>
                <th>Starts On</th>
                <th>Ends On</th>
                <th>Status</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              {heroOffers.map((offer) => (
                <tr key={offer._id}>
                  <td>{offer.title}</td>
                  <td>{offer.offerType}</td>
                  <td>{offer.priority}</td>
                  <td>{offer.startsAt ? new Date(offer.startsAt).toLocaleString() : "-"}</td>
                  <td>{offer.endsAt ? new Date(offer.endsAt).toLocaleString() : "-"}</td>
                  <td>{offer.status}</td>
                  <td>
                    <div className="row-actions">
                      <button
                        className="table-edit-btn"
                        onClick={() => startEditHeroOffer(offer)}
                      >
                        Edit
                      </button>
                      <button
                        className="table-delete-btn"
                        onClick={() => removeHeroOffer(offer._id)}
                      >
                        Delete
                      </button>
                    </div>
                  </td>
                </tr>
              ))}
              {heroOffers.length === 0 && (
                <tr>
                  <td colSpan="7">No hero offers added yet.</td>
                </tr>
              )}
            </tbody>
          </table>
        </section>
        )}
        {section === "products" && (
        <section className="admin-table-wrap">
          <h2>Current Products</h2>
          <table className="admin-table">
            <thead>
              <tr>
                <th>Name</th>
                <th>Tag</th>
                <th>Brand</th>
                <th>Colour Family</th>
                <th>Stock</th>
                <th>Price</th>
                <th>Rating</th>
                <th>Flash Sale</th>
                <th>Image</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              {products.map((product) => (
                <tr key={product._id}>
                  <td>{product.name}</td>
                  <td>{product.tag}</td>
                  <td>{product.brand || "Generic"}</td>
                  <td>{product.colorFamily || "Neutral"}</td>
                  <td>{Number(product.stock ?? 0)}</td>
                  <td>${product.price}</td>
                  <td>
                    {(product.ratingAverage || 0).toFixed(1)} / 5 ({product.ratingCount || 0})
                  </td>
                  <td>
                    {flashSaleProductIds.includes(String(product._id)) ? "Yes" : "No"}
                  </td>
                  <td>
                    {product.image ? (
                      <img
                        src={product.image}
                        alt={product.name}
                        className="admin-table-image"
                        onError={applyImageFallback}
                      />
                    ) : (
                      "No image"
                    )}
                  </td>
                  <td>
                    <div className="row-actions">
                      <button
                        className="table-edit-btn"
                        onClick={() => startEdit(product)}
                      >
                        Edit
                      </button>
                      <button
                        className="table-edit-btn"
                        onClick={() => toggleProductFlashSale(product._id)}
                      >
                        {flashSaleProductIds.includes(String(product._id))
                          ? "Remove Flash"
                          : "Add Flash"}
                      </button>
                      <button
                        className="table-delete-btn"
                        onClick={() => removeProduct(product._id)}
                      >
                        Delete
                      </button>
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </section>
        )}
        {section === "orders" && (
        <section className="admin-table-wrap admin-orders-wrap">
          <h2>Orders</h2>
          {pendingReturnOrders.length > 0 && (
            <div className="admin-return-alert">
              <p>
                <strong>{pendingReturnOrders.length}</strong> refund request(s) initiated by users
                need admin action.
              </p>
              <div className="admin-return-alert-list">
                {pendingReturnOrders.slice(0, 6).map((order) => (
                  <button
                    key={`return-alert-${order._id}`}
                    type="button"
                    className="admin-return-alert-item"
                    onClick={() => {
                      setSection("orders");
                      setSelectedOrderId(order._id);
                    }}
                  >
                    #{String(order._id).slice(-6)} • {order.user?.name || order.user?.email || "User"}
                  </button>
                ))}
              </div>
            </div>
          )}
          <div className="admin-orders-shell">
            <div>
              <div className="admin-order-filters admin-order-filters-modern">
                <select
                  value={orderFilters.orderStatus}
                  onChange={(e) =>
                    setOrderFilters((prev) => ({ ...prev, orderStatus: e.target.value }))
                  }
                >
                  <option value="all">Any status</option>
                  <option value="placed">Placed</option>
                  <option value="processing">Processing</option>
                  <option value="shipped">Shipped</option>
                  <option value="delivered">Delivered</option>
                </select>
                <select
                  value={orderFilters.priceRange}
                  onChange={(e) =>
                    setOrderFilters((prev) => ({ ...prev, priceRange: e.target.value }))
                  }
                >
                  <option value="all">All prices</option>
                  <option value="100-1500">$100-$1500</option>
                  <option value="100-500">$100-$500</option>
                  <option value="501-1000">$501-$1000</option>
                  <option value="1001-3000">$1001-$3000</option>
                </select>
                <input
                  placeholder="Search order, customer, promo"
                  value={orderFilters.search}
                  onChange={(e) =>
                    setOrderFilters((prev) => ({ ...prev, search: e.target.value }))
                  }
                />
                <select
                  value={orderFilters.sortByDate}
                  onChange={(e) =>
                    setOrderFilters((prev) => ({ ...prev, sortByDate: e.target.value }))
                  }
                >
                  <option value="newest">Sort by Date</option>
                  <option value="oldest">Oldest first</option>
                </select>
              </div>

              <table className="admin-table admin-order-table-modern">
                <thead>
                  <tr>
                    <th>
                      <input type="checkbox" aria-label="Select all orders" />
                    </th>
                    <th>Order</th>
                    <th>Customer</th>
                    <th>Status</th>
                    <th>Total</th>
                    <th>Date</th>
                    <th />
                  </tr>
                </thead>
                <tbody>
                  {filteredOrders.map((order) => (
                    <tr
                      key={order._id}
                      className={selectedOrder?._id === order._id ? "admin-row-selected" : ""}
                      onClick={() => setSelectedOrderId(order._id)}
                    >
                      <td>
                        <input
                          type="checkbox"
                          checked={selectedOrder?._id === order._id}
                          onChange={() => setSelectedOrderId(order._id)}
                          aria-label={`Select order ${order._id.slice(-6)}`}
                        />
                      </td>
                      <td>#{order._id.slice(-6)}</td>
                      <td>{order.user?.name || order.user?.email || "User"}</td>
                      <td>
                        <span className={`admin-status-pill admin-status-${order.paymentStatus || "pending"}`}>
                          {order.paymentStatus === "paid" ? "Paid" : "Pending"}
                        </span>
                        {String(order.returnRequest?.status || "none") === "requested" && (
                          <span className="admin-return-chip">Return Requested</span>
                        )}
                      </td>
                      <td>${Number(order.total || 0).toFixed(2)}</td>
                      <td>{new Date(order.createdAt).toLocaleDateString()}</td>
                      <td>...</td>
                    </tr>
                  ))}
                  {filteredOrders.length === 0 && (
                    <tr>
                      <td colSpan="7">No orders match your filters.</td>
                    </tr>
                  )}
                </tbody>
              </table>
            </div>

            <aside className="admin-order-details-pane">
              {!selectedOrder && <p>No order selected.</p>}
              {selectedOrder && (
                <>
                  <div className="admin-order-details-head">
                    <div>
                      <h3>Order #{selectedOrder._id.slice(-6)}</h3>
                      <p>{new Date(selectedOrder.createdAt).toLocaleString()}</p>
                    </div>
                  </div>
                  <div className="admin-order-details-meta">
                    <span className={`admin-status-pill admin-status-${selectedOrder.paymentStatus || "pending"}`}>
                      {selectedOrder.paymentStatus === "paid" ? "Paid" : "Pending"}
                    </span>
                    <span>{selectedOrder.promoCode || "No promo"}</span>
                    <select
                      value={selectedOrder.status}
                      onChange={(e) => updateOrderStatus(selectedOrder._id, e.target.value)}
                    >
                      <option value="placed">Placed</option>
                      <option value="processing">Processing</option>
                      <option value="shipped">Shipped</option>
                      <option value="delivered">Delivered</option>
                    </select>
                  </div>
                  <div className="admin-order-return-box">
                    <h4>Return & Refund</h4>
                    <p>
                      Return Status:{" "}
                      <strong>{String(selectedOrder.returnRequest?.status || "none")}</strong>
                    </p>
                    <p>
                      Payment Status:{" "}
                      <strong>{String(selectedOrder.paymentStatus || "pending")}</strong>
                    </p>
                    {selectedOrder.returnRequest?.reason && (
                      <p>Reason: {selectedOrder.returnRequest.reason}</p>
                    )}
                    {Array.isArray(selectedOrder.returnRequest?.evidence) &&
                      selectedOrder.returnRequest.evidence.length > 0 && (
                      <div className="admin-return-proof-grid">
                        {selectedOrder.returnRequest.evidence.map((file, idx) =>
                          file.type === "video" ? (
                            <video
                              key={`admin-return-proof-video-${idx}`}
                              src={file.url}
                              controls
                            />
                          ) : (
                            <img
                              key={`admin-return-proof-image-${idx}`}
                              src={file.url}
                              alt={file.name || "Defect proof"}
                              onError={applyImageFallback}
                            />
                          )
                        )}
                      </div>
                    )}

                    <input
                      placeholder="Admin note (optional)"
                      value={returnReviewNote}
                      onChange={(e) => setReturnReviewNote(e.target.value)}
                    />
                    <div className="admin-actions">
                      <button
                        type="button"
                        className="admin-primary-btn"
                        onClick={() => reviewReturnRequest(selectedOrder._id, "approve")}
                        disabled={selectedOrder.returnRequest?.status !== "requested"}
                      >
                        Approve Return
                      </button>
                      <button
                        type="button"
                        className="admin-secondary-btn"
                        onClick={() => reviewReturnRequest(selectedOrder._id, "reject")}
                        disabled={selectedOrder.returnRequest?.status !== "requested"}
                      >
                        Reject Return
                      </button>
                    </div>

                    <div className="admin-order-return-track-row">
                      <select
                        value={returnTrackingStatus}
                        onChange={(e) => setReturnTrackingStatus(e.target.value)}
                      >
                        <option value="approved">Approved</option>
                        <option value="in_transit">In Transit</option>
                        <option value="received">Received</option>
                        <option value="refund_initiated">Refund Initiated</option>
                        <option value="refunded">Refunded</option>
                        <option value="closed">Closed</option>
                      </select>
                      <button
                        type="button"
                        className="admin-primary-btn"
                        onClick={() => updateReturnTracking(selectedOrder._id, returnTrackingStatus)}
                      >
                        Update Return Tracking
                      </button>
                    </div>
                  </div>
                  <div className="admin-order-customer-card">
                    {selectedOrder.user?.avatar ? (
                      <img
                        src={selectedOrder.user.avatar}
                        alt={selectedOrder.user?.name || "User"}
                        onError={applyImageFallback}
                      />
                    ) : (
                      <div className="admin-customer-avatar-placeholder">
                        {(selectedOrder.user?.name || "U").slice(0, 1).toUpperCase()}
                      </div>
                    )}
                    <div>
                      <p>{selectedOrder.user?.name || "User"}</p>
                      <small>{selectedOrder.user?.email || "No email"}</small>
                    </div>
                  </div>
                  <div className="admin-order-contact-row">
                    {selectedOrder.user?.email && (
                      <a href={`mailto:${selectedOrder.user.email}`} aria-label="Email customer">
                        ✉
                      </a>
                    )}
                    {selectedOrder.user?.contactNumber && (
                      <a
                        href={`tel:${selectedOrder.user.contactNumber}`}
                        aria-label="Call customer"
                      >
                        ☎
                      </a>
                    )}
                  </div>
                  <h4>Order items</h4>
                  <div className="admin-order-item-list">
                    {(selectedOrder.items || []).map((item, idx) => (
                      <article className="admin-order-item-row" key={`${selectedOrder._id}-${idx}`}>
                        {item.image ? (
                          <img src={item.image} alt={item.name} onError={applyImageFallback} />
                        ) : (
                          <div className="admin-order-item-thumb" />
                        )}
                        <div>
                          <p>{item.name}</p>
                          <small>${Number(item.price || 0).toFixed(2)}</small>
                        </div>
                      </article>
                    ))}
                  </div>
                  <div className="admin-order-total-row">
                    <span>Total</span>
                    <strong>${Number(selectedOrder.total || 0).toFixed(2)}</strong>
                  </div>
                  <div className="admin-order-actions">
                    <button
                      type="button"
                      className="admin-track-btn"
                      onClick={() => handleTrackOrder(selectedOrder)}
                      disabled={selectedOrder.status === "delivered"}
                    >
                      {selectedOrder.status === "delivered" ? "Delivered" : "Track"}
                    </button>
                    <button
                      type="button"
                      className="admin-refund-btn"
                      onClick={() => handleRefundOrder(selectedOrder)}
                      disabled={selectedOrder.paymentStatus === "refunded"}
                    >
                      {selectedOrder.paymentStatus === "refunded" ? "Refunded" : "Refund"}
                    </button>
                  </div>
                </>
              )}
            </aside>
          </div>
        </section>
        )}
        {section === "services" && (
        <section className="admin-table-wrap admin-orders-wrap">
          <h2>Bike Service Requests</h2>
          <div className="admin-orders-shell">
            <div>
              <div className="admin-order-filters admin-order-filters-modern">
                <select
                  value={serviceFilters.packageType}
                  onChange={(e) =>
                    setServiceFilters((prev) => ({ ...prev, packageType: e.target.value }))
                  }
                >
                  <option value="all">All packages</option>
                  <option value="basic">Basic Tune-Up</option>
                  <option value="full">Full Service</option>
                  <option value="premium">Premium Care</option>
                </select>
                <select
                  value={serviceFilters.priority}
                  onChange={(e) =>
                    setServiceFilters((prev) => ({ ...prev, priority: e.target.value }))
                  }
                >
                  <option value="all">All priorities</option>
                  <option value="emergency">Emergency first</option>
                  <option value="normal">Normal</option>
                </select>
                <select
                  value={serviceFilters.status}
                  onChange={(e) =>
                    setServiceFilters((prev) => ({ ...prev, status: e.target.value }))
                  }
                >
                  <option value="all">Any status</option>
                  <option value="requested">Requested</option>
                  <option value="confirmed">Confirmed</option>
                  <option value="in_progress">In Progress</option>
                  <option value="completed">Completed</option>
                  <option value="cancelled">Cancelled</option>
                </select>
                <input
                  placeholder="Search customer, bike, phone, address"
                  value={serviceFilters.search}
                  onChange={(e) =>
                    setServiceFilters((prev) => ({ ...prev, search: e.target.value }))
                  }
                />
                <select
                  value={serviceFilters.sortByDate}
                  onChange={(e) =>
                    setServiceFilters((prev) => ({ ...prev, sortByDate: e.target.value }))
                  }
                >
                  <option value="newest">Sort by Date</option>
                  <option value="oldest">Oldest first</option>
                </select>
              </div>
              <table className="admin-table admin-order-table-modern">
                <thead>
                  <tr>
                    <th>Request</th>
                    <th>Customer</th>
                    <th>Priority</th>
                    <th>Package</th>
                    <th>Slot</th>
                    <th>Status</th>
                    <th />
                  </tr>
                </thead>
                <tbody>
                  {filteredServiceRequests.map((request) => (
                    <tr
                      key={request._id}
                      className={
                        selectedServiceRequest?._id === request._id ? "admin-row-selected" : ""
                      }
                      onClick={() => setSelectedServiceRequestId(request._id)}
                    >
                      <td>#{request._id.slice(-6)}</td>
                      <td>{request.user?.name || request.user?.email || "User"}</td>
                      <td>
                        {String(request.priority || "normal") === "emergency" ? (
                          <span className="admin-emergency-chip">Emergency</span>
                        ) : (
                          "Normal"
                        )}
                      </td>
                      <td>{request.packageType}</td>
                      <td>
                        {request.preferredDate} {request.preferredTime}
                      </td>
                      <td>
                        <span className="admin-status-pill admin-status-pending">
                          {String(request.status || "requested").replace("_", " ")}
                        </span>
                      </td>
                      <td>...</td>
                    </tr>
                  ))}
                  {filteredServiceRequests.length === 0 && (
                    <tr>
                      <td colSpan="7">No service requests match your filters.</td>
                    </tr>
                  )}
                </tbody>
              </table>
            </div>
            <aside className="admin-order-details-pane">
              {!selectedServiceRequest && <p>No service request selected.</p>}
              {selectedServiceRequest && (
                <>
                  <div className="admin-order-details-head">
                    <div>
                      <h3>Service #{selectedServiceRequest._id.slice(-6)}</h3>
                      <p>{new Date(selectedServiceRequest.createdAt).toLocaleString()}</p>
                    </div>
                  </div>
                  <div className="admin-order-details-meta">
                    <span className="admin-status-pill admin-status-pending">
                      {String(selectedServiceRequest.status || "requested").replace("_", " ")}
                    </span>
                    {String(selectedServiceRequest.priority || "normal") === "emergency" ? (
                      <span className="admin-emergency-chip">Emergency Priority</span>
                    ) : (
                      <span>Normal Priority</span>
                    )}
                    <span>{selectedServiceRequest.packageType}</span>
                  </div>
                  <div className="admin-service-detail-grid">
                    <p><strong>Bike:</strong> {selectedServiceRequest.bikeModel}</p>
                    <p>
                      <strong>Preferred Slot:</strong> {selectedServiceRequest.preferredDate}{" "}
                      {selectedServiceRequest.preferredTime}
                    </p>
                    <p><strong>Contact:</strong> {selectedServiceRequest.contactNumber}</p>
                    <p><strong>Pickup Address:</strong> {selectedServiceRequest.pickupAddress}</p>
                    {String(selectedServiceRequest.priority || "normal") === "emergency" && (
                      <p>
                        <strong>Breakdown Issue:</strong> {selectedServiceRequest.breakdownIssue || "-"}
                      </p>
                    )}
                    <p>
                      <strong>Coordinates:</strong>{" "}
                      {selectedServiceRequest.pickupLocation?.latitude},{" "}
                      {selectedServiceRequest.pickupLocation?.longitude}
                    </p>
                    <p>
                      <strong>Accuracy:</strong>{" "}
                      {selectedServiceRequest.pickupLocation?.accuracyMeters ?? "N/A"} meters
                    </p>
                    <p>
                      <strong>Captured At:</strong>{" "}
                      {selectedServiceRequest.pickupLocation?.capturedAt
                        ? new Date(selectedServiceRequest.pickupLocation.capturedAt).toLocaleString()
                        : "-"}
                    </p>
                    <p><strong>Customer Note:</strong> {selectedServiceRequest.notes || "-"}</p>
                  </div>
                  <div className="admin-service-map-wrap">
                    {selectedServiceRequest.pickupLocation?.latitude !== undefined &&
                      selectedServiceRequest.pickupLocation?.longitude !== undefined && (
                        <>
                          <a
                            href={`https://www.google.com/maps?q=${selectedServiceRequest.pickupLocation.latitude},${selectedServiceRequest.pickupLocation.longitude}`}
                            target="_blank"
                            rel="noreferrer"
                          >
                            Open Location in Maps
                          </a>
                          <iframe
                            title={`Service map ${selectedServiceRequest._id}`}
                            src={`https://maps.google.com/maps?q=${selectedServiceRequest.pickupLocation.latitude},${selectedServiceRequest.pickupLocation.longitude}&z=16&output=embed`}
                            loading="lazy"
                            referrerPolicy="no-referrer-when-downgrade"
                          />
                        </>
                      )}
                  </div>
                  <div className="admin-order-contact-row">
                    {selectedServiceRequest.user?.email && (
                      <a
                        href={`mailto:${selectedServiceRequest.user.email}`}
                        aria-label="Email customer"
                      >
                        ✉
                      </a>
                    )}
                    {selectedServiceRequest.contactNumber && (
                      <a
                        href={`tel:${selectedServiceRequest.contactNumber}`}
                        aria-label="Call customer"
                      >
                        ☎
                      </a>
                    )}
                  </div>
                  <div className="admin-order-return-box">
                    <h4>Update Service Request</h4>
                    <select
                      value={serviceTrackingStatus}
                      onChange={(e) => setServiceTrackingStatus(e.target.value)}
                    >
                      <option value="requested">Requested</option>
                      <option value="confirmed">Confirmed</option>
                      <option value="in_progress">In Progress</option>
                      <option value="completed">Completed</option>
                      <option value="cancelled">Cancelled</option>
                    </select>
                    <input
                      placeholder="Admin note (optional)"
                      value={serviceAdminNote}
                      onChange={(e) => setServiceAdminNote(e.target.value)}
                    />
                    <div className="admin-actions">
                      <button
                        type="button"
                        className="admin-primary-btn"
                        onClick={() =>
                          updateServiceStatus(
                            selectedServiceRequest._id,
                            serviceTrackingStatus,
                            serviceAdminNote
                          )
                        }
                      >
                        Save Service Update
                      </button>
                    </div>
                    <p>
                      <strong>Current Admin Note:</strong>{" "}
                      {selectedServiceRequest.adminNote || "-"}
                    </p>
                  </div>
                </>
              )}
            </aside>
          </div>
        </section>
        )}
        {section === "customers" && (
        <section className="admin-table-wrap">
          <h2>Customers</h2>
          <div className="admin-customers-layout">
            <div className="admin-customers-list">
              <table className="admin-table">
                <thead>
                  <tr>
                    <th>Name</th>
                    <th>Email</th>
                    <th>Total Orders</th>
                    <th>Total Spent</th>
                    <th>Last Order</th>
                  </tr>
                </thead>
                <tbody>
                  {customers.map((customer) => (
                    <tr
                      key={customer.email}
                      className={
                        selectedCustomer?.email === customer.email ? "admin-row-selected" : ""
                      }
                      onClick={() => setSelectedCustomerEmail(customer.email)}
                    >
                      <td>{customer.name}</td>
                      <td>{customer.email}</td>
                      <td>{customer.ordersCount}</td>
                      <td>${customer.totalSpent.toFixed(2)}</td>
                      <td>
                        {customer.lastOrderAt
                          ? new Date(customer.lastOrderAt).toLocaleString()
                          : "-"}
                      </td>
                    </tr>
                  ))}
                  {customers.length === 0 && (
                    <tr>
                      <td colSpan="5">No customer data available yet.</td>
                    </tr>
                  )}
                </tbody>
              </table>
            </div>

            <aside className="admin-customer-details">
              {!selectedCustomer && <p>No customer selected.</p>}
              {selectedCustomer && (
                <>
                  <div className="admin-customer-profile">
                    {selectedCustomer.avatar ? (
                      <img
                        src={selectedCustomer.avatar}
                        alt={selectedCustomer.name}
                        onError={applyImageFallback}
                      />
                    ) : (
                      <div className="admin-customer-avatar-placeholder">
                        {selectedCustomer.name.slice(0, 1).toUpperCase()}
                      </div>
                    )}
                    <div>
                      <h3>{selectedCustomer.name}</h3>
                      <p>{selectedCustomer.email}</p>
                      <p>{selectedCustomer.contactNumber || "No contact number"}</p>
                      <p>{selectedCustomer.deliveryAddress || "No delivery address"}</p>
                    </div>
                  </div>

                  <div className="admin-customer-stats">
                    <span>Orders: {selectedCustomer.ordersCount}</span>
                    <span>Total Spent: ${selectedCustomer.totalSpent.toFixed(2)}</span>
                  </div>

                  <h4>Orders by this customer</h4>
                  <div className="admin-customer-order-list">
                    {selectedCustomer.orders.map((order) => (
                      <article key={order.id} className="admin-customer-order-item">
                        {order.previewImages.length > 0 && (
                          <div className="admin-customer-order-images">
                            {order.previewImages.map((imgSrc, imgIndex) => (
                              <img
                                key={`${order.id}-img-${imgIndex}`}
                                src={imgSrc}
                                alt={`Order item ${imgIndex + 1}`}
                                onError={applyImageFallback}
                              />
                            ))}
                          </div>
                        )}
                        <p>
                          <strong>#{order.id.slice(-8)}</strong> • {order.status}
                        </p>
                        <p>
                          ${order.total.toFixed(2)} • {order.itemsCount} items
                        </p>
                        <p>{new Date(order.createdAt).toLocaleString()}</p>
                        <p>Promo: {order.promoCode}</p>
                      </article>
                    ))}
                  </div>
                </>
              )}
            </aside>
          </div>
        </section>
        )}
        {section === "inventory" && (
        <section className="admin-table-wrap">
          <h2>Inventory Alert Center</h2>
          <div className="admin-inventory-stats">
            <article className="admin-inventory-card">
              <p>Low stock items</p>
              <strong>{inventoryInsights.lowStock.length}</strong>
            </article>
            <article className="admin-inventory-card">
              <p>Out of stock items</p>
              <strong>{inventoryInsights.outOfStock.length}</strong>
            </article>
            <article className="admin-inventory-card">
              <p>Restock reminders</p>
              <strong>{inventoryInsights.restockReminders.length}</strong>
            </article>
          </div>

          <table className="admin-table">
            <thead>
              <tr>
                <th>Product</th>
                <th>Brand</th>
                <th>Category</th>
                <th>Stock</th>
                <th>Status</th>
                <th>Reminder</th>
              </tr>
            </thead>
            <tbody>
              {products.map((product) => {
                const stock = Number(product.stock ?? 0);
                const status =
                  stock <= 0 ? "Out of stock" : stock <= 5 ? "Low stock" : "In stock";
                const reminder =
                  stock <= 0
                    ? "Restock immediately"
                    : stock <= 5
                      ? "Restock in 24h"
                      : stock <= 10
                        ? "Plan restock this week"
                        : "Healthy stock";
                return (
                  <tr key={`inventory-${product._id}`}>
                    <td>{product.name}</td>
                    <td>{product.brand || "Generic"}</td>
                    <td>{product.tag || "General"}</td>
                    <td>{stock}</td>
                    <td>
                      <span
                        className={`admin-inventory-pill ${
                          stock <= 0
                            ? "danger"
                            : stock <= 5
                              ? "warning"
                              : stock <= 10
                                ? "notice"
                                : "ok"
                        }`}
                      >
                        {status}
                      </span>
                    </td>
                    <td>{reminder}</td>
                  </tr>
                );
              })}
              {products.length === 0 && (
                <tr>
                  <td colSpan="6">No products found for inventory monitoring.</td>
                </tr>
              )}
            </tbody>
          </table>
        </section>
        )}
        {section === "performance" && (
        <section className="admin-table-wrap">
          <h2>Product Performance Insights</h2>
          <div className="admin-performance-stats">
            <article className="admin-performance-card">
              <p>Average rating</p>
              <strong>{productPerformance.avgRating.toFixed(1)} / 5</strong>
            </article>
            <article className="admin-performance-card">
              <p>Rated products</p>
              <strong>{productPerformance.ratedCount}</strong>
            </article>
            <article className="admin-performance-card">
              <p>Needs attention</p>
              <strong>{productPerformance.needsAttentionCount}</strong>
            </article>
          </div>

          <div className="admin-performance-highlights">
            <div className="admin-performance-list">
              <h3>Top Rated</h3>
              {productPerformance.topRated.map((product) => (
                <p key={`top-rated-${product._id}`}>
                  {product.name} • {product.rating.toFixed(1)}★ ({product.reviews})
                </p>
              ))}
              {productPerformance.topRated.length === 0 && <p>No rated products yet.</p>}
            </div>
            <div className="admin-performance-list">
              <h3>Most Reviewed</h3>
              {productPerformance.mostReviewed.map((product) => (
                <p key={`most-reviewed-${product._id}`}>
                  {product.name} • {product.reviews} reviews ({product.rating.toFixed(1)}★)
                </p>
              ))}
              {productPerformance.mostReviewed.length === 0 && <p>No reviews yet.</p>}
            </div>
          </div>

          <table className="admin-table">
            <thead>
              <tr>
                <th>Rank</th>
                <th>Product</th>
                <th>Rating</th>
                <th>Reviews</th>
                <th>Stock</th>
                <th>Performance Score</th>
              </tr>
            </thead>
            <tbody>
              {productPerformance.ranked.map((product, index) => (
                <tr key={`performance-${product._id}`}>
                  <td>#{index + 1}</td>
                  <td>{product.name}</td>
                  <td>{product.rating.toFixed(1)} / 5</td>
                  <td>{product.reviews}</td>
                  <td>{product.stock}</td>
                  <td>{product.score}</td>
                </tr>
              ))}
              {productPerformance.ranked.length === 0 && (
                <tr>
                  <td colSpan="6">No products available for performance analysis.</td>
                </tr>
              )}
            </tbody>
          </table>
        </section>
        )}
        {section === "featured" && (
        <section className="admin-form-wrap">
          <h2>Flash Sale Products (Deals of the Day)</h2>
          <p className="admin-hint">
            Pick products shown in the shop Flash Sale section. Selected:{" "}
            <strong>{flashSaleProductIds.length}</strong>
          </p>
          <div className="admin-flash-product-grid">
            {products.map((product) => {
              const isSelected = flashSaleProductIds.includes(String(product._id));
              return (
                <label
                  key={`flash-${product._id}`}
                  className={`admin-flash-product-card ${isSelected ? "selected" : ""}`}
                >
                  <input
                    type="checkbox"
                    checked={isSelected}
                    onChange={() => toggleFlashSaleProduct(product._id)}
                  />
                  {product.image ? (
                    <img src={product.image} alt={product.name} onError={applyImageFallback} />
                  ) : (
                    <div className="admin-flash-thumb-placeholder">No image</div>
                  )}
                  <div>
                    <p>{product.name}</p>
                    <small>${Number(product.price || 0).toFixed(2)}</small>
                  </div>
                </label>
              );
            })}
          </div>
          <div className="admin-actions">
            <button onClick={saveFlashSaleProducts} className="admin-primary-btn">
              Save Flash Sale Products
            </button>
          </div>
        </section>
        )}
        {section === "featured" && (
        <section className="admin-form-wrap">
          <h2>{editingFeaturedSectionId ? "Edit Featured Section" : "Create Featured Section"}</h2>
          <p className="admin-hint">
            The <strong>Deals of the Day</strong> section powers Flash Sale products in shop.
          </p>
          <div className="admin-form-grid">
            <select
              value={featuredSectionForm.key}
              onChange={(e) =>
                setFeaturedSectionForm((prev) => ({ ...prev, key: e.target.value }))
              }
            >
              <option value="trending">🔥 Trending Products</option>
              <option value="new-arrivals">🆕 New Arrivals</option>
              <option value="best-sellers">💎 Best Sellers</option>
              <option value="deals-of-day">💰 Deals of the Day</option>
              <option value="top-electronics">📱 Top Electronics</option>
              <option value="top-fashion">👟 Top Fashion</option>
            </select>
            <input
              placeholder="Section title"
              value={featuredSectionForm.title}
              onChange={(e) =>
                setFeaturedSectionForm((prev) => ({ ...prev, title: e.target.value }))
              }
            />
            <input
              type="number"
              min="0"
              placeholder="Sort order"
              value={featuredSectionForm.sortOrder}
              onChange={(e) =>
                setFeaturedSectionForm((prev) => ({ ...prev, sortOrder: e.target.value }))
              }
            />
            <select
              value={featuredSectionForm.isActive ? "active" : "inactive"}
              onChange={(e) =>
                setFeaturedSectionForm((prev) => ({
                  ...prev,
                  isActive: e.target.value === "active"
                }))
              }
            >
              <option value="active">Active</option>
              <option value="inactive">Inactive</option>
            </select>
            <select
              multiple
              className="admin-multi-select"
              value={featuredSectionForm.productIds}
              onChange={(e) => {
                const selected = Array.from(e.target.selectedOptions).map((opt) => opt.value);
                setFeaturedSectionForm((prev) => ({ ...prev, productIds: selected }));
              }}
            >
              {products.map((product) => (
                <option key={product._id} value={product._id}>
                  {product.name} (${Number(product.price || 0).toFixed(2)})
                </option>
              ))}
            </select>
          </div>
          <p className="admin-hint">Hold Ctrl/Cmd to select multiple products.</p>
          <div className="admin-actions">
            <button onClick={createFeaturedSection} className="admin-primary-btn">
              {editingFeaturedSectionId ? "Update Featured Section" : "Add Featured Section"}
            </button>
            {editingFeaturedSectionId && (
              <button onClick={resetFeaturedSectionForm} className="admin-secondary-btn">
                Cancel Edit
              </button>
            )}
          </div>
        </section>
        )}
        {section === "featured" && (
        <section className="admin-table-wrap">
          <h2>Featured Sections</h2>
          <table className="admin-table">
            <thead>
              <tr>
                <th>Key</th>
                <th>Title</th>
                <th>Products</th>
                <th>Sort</th>
                <th>Status</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              {featuredSections.map((row) => (
                <tr key={row._id}>
                  <td>{row.key}</td>
                  <td>{row.title}</td>
                  <td>{Array.isArray(row.products) ? row.products.length : 0}</td>
                  <td>{row.sortOrder}</td>
                  <td>{row.isActive ? "active" : "inactive"}</td>
                  <td>
                    <div className="row-actions">
                      <button
                        className="table-edit-btn"
                        onClick={() => startEditFeaturedSection(row)}
                      >
                        Edit
                      </button>
                      <button
                        className="table-delete-btn"
                        onClick={() => removeFeaturedSection(row._id)}
                      >
                        Delete
                      </button>
                    </div>
                  </td>
                </tr>
              ))}
              {featuredSections.length === 0 && (
                <tr>
                  <td colSpan="6">No featured sections added yet.</td>
                </tr>
              )}
            </tbody>
          </table>
        </section>
        )}
    </>
  );
}
