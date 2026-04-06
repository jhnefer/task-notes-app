import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import axios from "axios";
import { User } from "@shared/schema";
import { toast } from "sonner";

const api = axios.create({ baseURL: "/api" });

export function useAuth() {
  const queryClient = useQueryClient();

  const { data: user, isLoading, isError } = useQuery<User | null>({
    queryKey: ["user"],
    queryFn: async () => {
      try {
        const res = await api.get("/user");
        return res.data;
      } catch {
        return null;
      }
    },
    retry: false,
  });

  const loginMutation = useMutation({
    mutationFn: async (credentials: any) => (await api.post("/login", credentials)).data,
    onSuccess: (user) => {
      queryClient.setQueryData(["user"], user);
      toast.success("Bem-vindo de volta!");
    },
    onError: () => toast.error("Usuário ou senha inválidos"),
  });

  const registerMutation = useMutation({
    mutationFn: async (credentials: any) => (await api.post("/register", credentials)).data,
    onSuccess: (user) => {
      queryClient.setQueryData(["user"], user);
      toast.success("Conta criada com sucesso!");
    },
    onError: (err: any) => toast.error(err.response?.data || "Erro ao registrar"),
  });

  const logoutMutation = useMutation({
    mutationFn: async () => await api.post("/logout"),
    onSuccess: () => {
      queryClient.setQueryData(["user"], null);
      queryClient.invalidateQueries();
      toast.info("Você saiu do sistema");
    },
  });

  return {
    user,
    isLoading,
    isError,
    login: loginMutation.mutateAsync,
    register: registerMutation.mutateAsync,
    logout: logoutMutation.mutateAsync,
    isLoggingIn: loginMutation.isPending,
    isRegistering: registerMutation.isPending,
  };
}
