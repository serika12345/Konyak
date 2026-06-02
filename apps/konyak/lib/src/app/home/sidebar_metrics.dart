const defaultSidebarTopPadding = 12.0;
const sidebarTopPaddingWithWindowControls = 52.0;

double sidebarTopPadding({required bool reserveLeadingWindowControlsSpace}) {
  return reserveLeadingWindowControlsSpace
      ? sidebarTopPaddingWithWindowControls
      : defaultSidebarTopPadding;
}
