import React, { useState, useEffect } from "react";
import { createCategory, fetchCategories } from "../services/api";
import { Category, CategoryFormData } from "../types";
import { Modal, Button } from "../vibes";
import { COLORS } from "../constants/colors";
import { CategoryForm } from "../components/CategoryForm";
import { CategoryTable } from "../components/CategoryTable";

const CategoryPage: React.FC = () => {
  const [categories, setCategories] = useState<Category[]>([]);
  const [loading, setLoading] = useState(true);
  const [isModalOpen, setIsModalOpen] = useState(false);

  useEffect(() => {
    loadCategories();
  }, []);

  const loadCategories = async () => {
    try {
      setLoading(true);
      const data = await fetchCategories();
      setCategories(data);
    } catch (error) {
      console.error("Error fetching categories:", error);
    } finally {
      setLoading(false);
    }
  };

  const handleAddCategory = async (data: CategoryFormData) => {
    try {
      await createCategory(data);
      setIsModalOpen(false);
      loadCategories();
    } catch (error) {
      console.error("Error creating category:", error);
      throw error;
    }
  };

  const pageStyle: React.CSSProperties = {
    padding: "48px 64px",
    minHeight: "100vh",
    background: COLORS.secondary.s01,
  };

  const headerStyle: React.CSSProperties = {
    display: "flex",
    alignItems: "center",
    gap: "24px",
    justifyContent: "space-between",
  };

  const leftHeaderStyle: React.CSSProperties = {
    display: "flex",
    alignItems: "center",
    gap: "24px",
  };

  const titleStyle: React.CSSProperties = {
    fontSize: "40px",
    fontWeight: 700,
    color: COLORS.secondary.s10,
    margin: 0,
    flexShrink: 0,
  };

  const loadingStyle: React.CSSProperties = {
    display: "flex",
    justifyContent: "center",
    alignItems: "center",
    padding: "48px",
    fontSize: "18px",
    color: COLORS.secondary.s08,
  };

  return (
    <div style={pageStyle}>
      <div style={headerStyle}>
        <div style={leftHeaderStyle}>
          <h1 style={titleStyle}>Category List</h1>
        </div>
        <Button
          variant="primary"
          onClick={() => {
            setIsModalOpen(true);
          }}
        >
          Add Category
        </Button>
      </div>

      <div>
        {loading ? (
          <div style={loadingStyle}>Loading...</div>
        ) : (
          <div style={{ marginTop: "32px" }}>
            <CategoryTable categories={categories} onCategoryUpdated={loadCategories} />
          </div>
        )}
      </div>

      <Modal
        isOpen={isModalOpen}
        onClose={() => setIsModalOpen(false)}
        title="Add New Category"
      >
        <CategoryForm
          onSubmit={handleAddCategory}
          onCancel={() => setIsModalOpen(false)}
        />
      </Modal>
    </div>
  );
};

export default CategoryPage;
