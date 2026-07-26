import { Navigate, Route, Routes } from 'react-router-dom';
import { Layout } from './components/Layout';
import { LoginPage } from './pages/LoginPage';
import { OverviewPage } from './pages/OverviewPage';
import { UsersPage } from './pages/UsersPage';
import { VehiclesPage } from './pages/VehiclesPage';
import { PartnersPage } from './pages/PartnersPage';
import { InspectionsPage } from './pages/InspectionsPage';
import { BookingsPage } from './pages/BookingsPage';
import { SupportPage } from './pages/SupportPage';
import { WarrantyPage } from './pages/WarrantyPage';
import { InsurancePage } from './pages/InsurancePage';
import { RoadsidePage } from './pages/RoadsidePage';
import { ConciergePage } from './pages/ConciergePage';
import { ListingsPage } from './pages/ListingsPage';
import { CmsPage } from './pages/CmsPage';
import { PromotionsPage } from './pages/PromotionsPage';
import { RevenuePage } from './pages/RevenuePage';
import { AuditLogPage } from './pages/AuditLogPage';
import { useAuth } from './state/AuthContext';

export function App() {
  const { isAuthenticated } = useAuth();

  if (!isAuthenticated) {
    return <LoginPage />;
  }

  return (
    <Routes>
      <Route element={<Layout />}>
        <Route path="/" element={<OverviewPage />} />
        <Route path="/users" element={<UsersPage />} />
        <Route path="/vehicles" element={<VehiclesPage />} />
        <Route path="/partners" element={<PartnersPage />} />
        <Route path="/inspections" element={<InspectionsPage />} />
        <Route path="/bookings" element={<BookingsPage />} />
        <Route path="/support" element={<SupportPage />} />
        <Route path="/warranty" element={<WarrantyPage />} />
        <Route path="/insurance" element={<InsurancePage />} />
        <Route path="/roadside" element={<RoadsidePage />} />
        <Route path="/concierge" element={<ConciergePage />} />
        <Route path="/listings" element={<ListingsPage />} />
        <Route path="/cms" element={<CmsPage />} />
        <Route path="/promotions" element={<PromotionsPage />} />
        <Route path="/revenue" element={<RevenuePage />} />
        <Route path="/audit-log" element={<AuditLogPage />} />
        <Route path="*" element={<Navigate to="/" replace />} />
      </Route>
    </Routes>
  );
}
