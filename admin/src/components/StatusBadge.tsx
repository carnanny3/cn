const GREEN = new Set(['verified', 'completed', 'active', 'green', 'captured', 'issued']);
const AMBER = new Set(['pending', 'in_progress', 'assigned', 'amber', 'qa_review', 'booked', 'refunded']);
const RED = new Set(['rejected', 'cancelled', 'suspended', 'red', 'failed', 'void']);

export function StatusBadge({ status }: { status: string }) {
  let className = 'badge badge-neutral';
  if (GREEN.has(status)) className = 'badge badge-green';
  else if (AMBER.has(status)) className = 'badge badge-amber';
  else if (RED.has(status)) className = 'badge badge-red';

  return <span className={className}>{status.replace(/_/g, ' ')}</span>;
}
