// Helpers for the file upload support.

use crate::builder::{Directory, DirectoryBuilder, FileBuilder};
use anyhow::Result;
use async_recursion::async_recursion;

#[derive(Debug)]
struct FileNode<T: tokio::io::AsyncRead + 'static + std::marker::Send> {
    name: String,
    content: T,
}

#[derive(Debug)]
struct DirNode<T: tokio::io::AsyncRead + 'static + std::marker::Send> {
    name: String,
    entries: Vec<TreeNode<T>>,
}

impl<T: tokio::io::AsyncRead + 'static + std::marker::Send> DirNode<T> {
    fn root() -> Self {
        DirNode {
            name: "".into(),
            entries: vec![],
        }
    }

    fn subdir_index(&self, name: &str) -> i32 {
        for (index, entry) in self.entries.iter().enumerate() {
            if let TreeNode::Dir(dir) = entry {
                if dir.name == name {
                    return index as _;
                }
            }
        }
        -1
    }

    fn add_subdir(&mut self, name: &str) -> i32 {
        self.entries.push(TreeNode::Dir(DirNode {
            name: name.into(),
            entries: vec![],
        }));
        self.entries.len() as i32 - 1
    }

    fn ensure_subdirs_and_file(&mut self, mut names: Vec<String>, content: T) {
        if names.len() == 1 {
            self.add_file(FileNode {
                name: names[0].clone(),
                content,
            });
            return;
        }

        let name = names.remove(0);
        let mut index = self.subdir_index(&name);
        if index == -1 {
            index = self.add_subdir(&name);
        }

        match self.entries[index as usize] {
            TreeNode::Dir(ref mut dir) => {
                dir.ensure_subdirs_and_file(names, content);
            }
            _ => {}
        }
    }

    fn add_file(&mut self, file: FileNode<T>) {
        self.entries.push(TreeNode::File(file));
    }
}

#[derive(Debug)]
enum TreeNode<T: tokio::io::AsyncRead + 'static + std::marker::Send> {
    File(FileNode<T>),
    Dir(DirNode<T>),
}

fn build_tree_from_file_list<T: tokio::io::AsyncRead + 'static + std::marker::Send>(
    files: Vec<(T, String)>,
) -> DirNode<T> {
    let mut root = DirNode::root();

    for (content, path) in files {
        let parts: Vec<String> = path.split('/').map(|s| s.to_owned()).collect();
        if !parts.is_empty() {
            root.ensure_subdirs_and_file(parts, content);
        }
    }

    root
}

#[async_recursion]
async fn make_dir_from_tree<T: tokio::io::AsyncRead + 'static + std::marker::Send>(
    root: DirNode<T>,
) -> Result<Directory> {
    let mut dir = DirectoryBuilder::new().name(root.name);
    for entry in root.entries {
        match entry {
            TreeNode::Dir(subdir) => {
                let d = make_dir_from_tree(subdir).await?;
                dir = dir.add_dir(d)?;
            }
            TreeNode::File(file) => {
                let file_builder = FileBuilder::new()
                    .content_reader(file.content)
                    .name(&file.name);
                let file = file_builder.build().await?;
                dir = dir.add_file(file);
            }
        }
    }
    dir.build().await
}

pub async fn make_dir_from_file_list<T: tokio::io::AsyncRead + 'static + std::marker::Send>(
    files: Vec<(T, String)>,
) -> Result<Directory> {
    make_dir_from_tree(build_tree_from_file_list(files)).await
}
