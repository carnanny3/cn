import { NavLink, Outlet } from 'react-router-dom';
import { useAuth } from '../state/AuthContext';

// Mirrors the backend's RBAC groups (Section 19.1 of the PRD). Omitting
// `roles` means every admin role can see the item (e.g. Overview).
const NAV_ITEMS: { to: string; label: string; end?: boolean; roles?: string[] }[] = [
  { to: '/', label: 'Overview', end: true },
  { to: '/users', label: 'Users', roles: ['admin_super', 'admin_support'] },
  { to: '/vehicles', label: 'Vehicles', roles: ['admin_super', 'admin_support', 'admin_ops'] },
  { to: '/partners', label: 'Partners', roles: ['admin_super', 'admin_partner_manager'] },
  { to: '/inspections', label: 'Inspections', roles: ['admin_super', 'admin_inspection'] },
  { to: '/bookings', label: 'Bookings', roles: ['admin_super', 'admin_ops'] },
  { to: '/support', label: 'Support Tickets', roles: ['admin_super', 'admin_support'] },
  { to: '/warranty', label: 'Warranty Claims', roles: ['admin_super', 'admin_ops'] },
  { to: '/insurance', label: 'Insurance Quotes', roles: ['admin_super', 'admin_ops'] },
  { to: '/roadside', label: 'Roadside', roles: ['admin_super', 'admin_ops'] },
  { to: '/concierge', label: 'Concierge', roles: ['admin_super', 'admin_ops'] },
  { to: '/listings', label: 'Buy-a-Car Listings', roles: ['admin_super', 'admin_ops'] },
  { to: '/cms', label: 'CMS & FAQs', roles: ['admin_super', 'admin_content'] },
  { to: '/promotions', label: 'Promotions', roles: ['admin_super', 'admin_content'] },
  { to: '/revenue', label: 'Payments & Revenue', roles: ['admin_super', 'admin_finance', 'admin_analyst'] },
  { to: '/audit-log', label: 'Audit Log', roles: ['admin_super', 'admin_compliance'] },
];

export function Layout() {
  const { logout, role } = useAuth();
  const visibleItems = NAV_ITEMS.filter((item) => !item.roles || (role && item.roles.includes(role)));

  return (
    <div className="app-shell">
      <aside className="sidebar">
        <div className="sidebar-brand">
          <img src="/icon-192.png" alt="Car Nanny" />
          <h1>Car Nanny Admin</h1>
        </div>
        <nav>
          {visibleItems.map((item) => (
            <NavLink
              key={item.to}
              to={item.to}
              end={item.end}
              className={({ isActive }) => (isActive ? 'active' : '')}
            >
              {item.label}
            </NavLink>
          ))}
        </nav>
        <div style={{ marginTop: 32 }}>
          <button className="secondary" onClick={logout}>
            Log out
          </button>
        </div>
      </aside>
      <main className="main-content">
        <Outlet />
      </main>
    </div>
  );
}
