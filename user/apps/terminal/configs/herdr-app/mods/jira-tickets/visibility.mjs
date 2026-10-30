export function isBlockVisible(node, block) {
  if (!block || !node || node.hidden || node.size?.px === 0) return false;
  if (node.id === block) return true;
  const children = node.children || [];
  const active = node.active ?? children[0]?.id;
  return children.some(child => (node.type !== 'stack' || child.id === active) && isBlockVisible(child, block));
}
