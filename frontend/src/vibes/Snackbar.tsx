/**
 * Reusable Snackbar component
 */

import React, { useEffect, useState } from "react";
import { COLORS } from "../constants/colors";

type SnackbarVariant = "success" | "error" | "info";

interface SnackbarMessage {
  id: number;
  message: string;
  variant: SnackbarVariant;
}

type Listener = (snackbar: SnackbarMessage) => void;

let listener: Listener | null = null;
let idCounter = 0;

export function showSnackbar(
  message: string,
  variant: SnackbarVariant = "info",
) {
  idCounter += 1;
  const snackbar: SnackbarMessage = { id: idCounter, message, variant };
  listener?.(snackbar);
}

const VARIANT_STYLES: Record<SnackbarVariant, { background: string; color: string }> = {
  success: { background: COLORS.success, color: "#fff" },
  error: { background: COLORS.danger, color: "#fff" },
  info: { background: COLORS.info, color: "#fff" },
};

const AUTO_DISMISS_MS = 3000;

export function SnackbarContainer() {
  const [current, setCurrent] = useState<SnackbarMessage | null>(null);

  useEffect(() => {
    listener = (snackbar) => setCurrent(snackbar);
    return () => {
      listener = null;
    };
  }, []);

  useEffect(() => {
    if (!current) return;

    const timer = setTimeout(() => setCurrent(null), AUTO_DISMISS_MS);
    return () => clearTimeout(timer);
  }, [current]);

  if (!current) return null;

  const variantStyle = VARIANT_STYLES[current.variant];

  const containerStyle: React.CSSProperties = {
    position: "fixed",
    bottom: "24px",
    left: "24px",
    zIndex: 2000,
    display: "flex",
    alignItems: "center",
    gap: "12px",
    padding: "12px 20px",
    borderRadius: "0.5rem",
    boxShadow: "0 4px 6px rgba(0, 0, 0, 0.15)",
    fontSize: "0.9rem",
    fontWeight: 500,
    background: variantStyle.background,
    color: variantStyle.color,
    maxWidth: "90vw",
  };

  const closeButtonStyle: React.CSSProperties = {
    background: "none",
    border: "none",
    color: variantStyle.color,
    cursor: "pointer",
    fontSize: "1.1rem",
    lineHeight: 1,
    padding: 0,
    opacity: 0.8,
  };

  return (
    <div style={containerStyle} role="status">
      <span>{current.message}</span>
      <button
        style={closeButtonStyle}
        onClick={() => setCurrent(null)}
        aria-label="Dismiss"
      >
        ×
      </button>
    </div>
  );
}